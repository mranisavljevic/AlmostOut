import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { QueryDocumentSnapshot } from "firebase-admin/firestore";

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Types for our data structures
interface ListData {
  name: string;
  members: Record<string, {
    role: "owner" | "editor" | "viewer";
    displayName: string;
  }>;
}

interface ItemData {
  name: string;
  addedBy: string;
  addedByName: string;
  completedBy?: string;
  completedByName?: string;
  isCompleted: boolean;
  images?: Array<{
    id: string;
    url: string;
    type: string;
  }>;
}

interface UserData {
  displayName?: string;
  fcmTokens?: string[];
  preferences?: {
    pushNotifications: boolean;
  };
}

interface InvitationData {
  listId: string;
  listName: string;
  invitedBy: string;
  invitedByName: string;
  invitedEmail: string;
  role: "owner" | "editor" | "viewer";
  status: "pending" | "accepted" | "declined" | "expired";
  expiresAt: admin.firestore.Timestamp;
}

// Update list statistics when items change
export const updateListStats = functions.firestore
  .document("lists/{listId}/items/{itemId}")
  .onWrite(async (change, context): Promise<void> => {
    const listId = context.params.listId as string;
    
    try {
      const itemsSnapshot = await db
        .collection("lists")
        .doc(listId)
        .collection("items")
        .get();
      
      const totalItems = itemsSnapshot.size;
      const completedItems = itemsSnapshot.docs.filter(
        (doc: QueryDocumentSnapshot) => doc.data().isCompleted === true
      ).length;
      
      await db.collection("lists").doc(listId).update({
        totalItems,
        completedItems,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      functions.logger.info(`Updated stats for list ${listId}: ${completedItems}/${totalItems}`);
    } catch (error) {
      functions.logger.error("Error updating list stats:", error);
    }
  });

// Send notification when item is added
export const onItemAdded = functions.firestore
  .document("lists/{listId}/items/{itemId}")
  .onCreate(async (snap, context): Promise<void> => {
    const listId = context.params.listId as string;
    const item = snap.data() as ItemData;
    
    try {
      // Get list details
      const listDoc = await db.collection("lists").doc(listId).get();
      const listData = listDoc.data() as ListData | undefined;
      
      if (!listData) {
        functions.logger.warn(`List ${listId} not found`);
        return;
      }
      
      // Get FCM tokens for all members except the one who added the item
      const memberIds = Object.keys(listData.members).filter(
        (memberId: string) => memberId !== item.addedBy
      );
      
      const userDocs = await Promise.all(
        memberIds.map((id: string) => db.collection("users").doc(id).get())
      );
      
      const fcmTokens: string[] = [];
      userDocs.forEach((doc) => {
        const userData = doc.data() as UserData | undefined;
        if (userData?.fcmTokens && userData.preferences?.pushNotifications !== false) {
          fcmTokens.push(...userData.fcmTokens);
        }
      });
      
      if (fcmTokens.length === 0) {
        functions.logger.info("No FCM tokens found for notification");
        return;
      }
      
      const hasImages = item.images && item.images.length > 0;
      const message: admin.messaging.MulticastMessage = {
        notification: {
          title: listData.name,
          body: `${item.addedByName} added "${item.name}"${hasImages ? " with photo" : ""}`,
        },
        data: {
          listId: listId,
          itemId: snap.id,
          type: "item_added",
        },
        tokens: fcmTokens,
      };
      
      const response = await messaging.sendMulticast(message);
      functions.logger.info(`Sent notification for new item in list ${listId}. Success: ${response.successCount}, Failure: ${response.failureCount}`);
      
      // Log failed tokens for cleanup
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(fcmTokens[idx]);
            functions.logger.warn(`Failed to send to token: ${resp.error?.message}`);
          }
        });
        
        // Clean up invalid tokens
        await cleanupInvalidTokens(memberIds, failedTokens);
      }
    } catch (error) {
      functions.logger.error("Error sending notification:", error);
    }
  });

// Send notification when item is completed
export const onItemCompleted = functions.firestore
  .document("lists/{listId}/items/{itemId}")
  .onUpdate(async (change, context): Promise<void> => {
    const before = change.before.data() as ItemData;
    const after = change.after.data() as ItemData;
    
    // Only trigger if item was just completed
    if (before.isCompleted === false && after.isCompleted === true) {
      const listId = context.params.listId as string;
      
      try {
        // Get list details
        const listDoc = await db.collection("lists").doc(listId).get();
        const listData = listDoc.data() as ListData | undefined;
        
        if (!listData) {
          functions.logger.warn(`List ${listId} not found`);
          return;
        }
        
        // Get FCM tokens for all members except the one who completed the item
        const memberIds = Object.keys(listData.members).filter(
          (memberId: string) => memberId !== after.completedBy
        );
        
        const userDocs = await Promise.all(
          memberIds.map((id: string) => db.collection("users").doc(id).get())
        );
        
        const fcmTokens: string[] = [];
        userDocs.forEach((doc) => {
          const userData = doc.data() as UserData | undefined;
          if (userData?.fcmTokens && userData.preferences?.pushNotifications !== false) {
            fcmTokens.push(...userData.fcmTokens);
          }
        });
        
        if (fcmTokens.length === 0) {
          functions.logger.info("No FCM tokens found for completion notification");
          return;
        }
        
        const message: admin.messaging.MulticastMessage = {
          notification: {
            title: listData.name,
            body: `${after.completedByName} completed "${after.name}"`,
          },
          data: {
            listId: listId,
            itemId: change.after.id,
            type: "item_completed",
          },
          tokens: fcmTokens,
        };
        
        const response = await messaging.sendMulticast(message);
        functions.logger.info(`Sent completion notification for item in list ${listId}. Success: ${response.successCount}, Failure: ${response.failureCount}`);
      } catch (error) {
        functions.logger.error("Error sending completion notification:", error);
      }
    }
  });

// Clean up expired invitations
export const cleanupExpiredInvitations = functions.pubsub
  .schedule("0 2 * * *") // Daily at 2 AM
  .timeZone("UTC")
  .onRun(async (): Promise<void> => {
    try {
      const expiredInvitations = await db
        .collection("invitations")
        .where("expiresAt", "<", admin.firestore.Timestamp.now())
        .where("status", "==", "pending")
        .get();
      
      if (expiredInvitations.empty) {
        functions.logger.info("No expired invitations to clean up");
        return;
      }
      
      const batch = db.batch();
      expiredInvitations.docs.forEach((doc) => {
        batch.update(doc.ref, { status: "expired" });
      });
      
      await batch.commit();
      functions.logger.info(`Marked ${expiredInvitations.size} invitations as expired`);
    } catch (error) {
      functions.logger.error("Error cleaning up expired invitations:", error);
    }
  });

// Log activity when items are modified
export const logActivity = functions.firestore
  .document("lists/{listId}/items/{itemId}")
  .onWrite(async (change, context): Promise<void> => {
    const listId = context.params.listId as string;
    const itemId = context.params.itemId as string;
    
    try {
      let activityType = "";
      let details: Record<string, any> = {};
      let userId = "";
      let userName = "";
      
      if (!change.before.exists) {
        // Item was created
        activityType = "item_added";
        const item = change.after.data() as ItemData;
        details = {
          itemName: item.name,
          itemId: itemId,
        };
        userId = item.addedBy;
        userName = item.addedByName;
      } else if (!change.after.exists) {
        // Item was deleted
        activityType = "item_deleted";
        const item = change.before.data() as ItemData;
        details = {
          itemName: item.name,
          itemId: itemId,
        };
        userId = item.addedBy;
        userName = item.addedByName;
      } else {
        // Item was updated
        const before = change.before.data() as ItemData;
        const after = change.after.data() as ItemData;
        
        if (before.isCompleted !== after.isCompleted) {
          activityType = after.isCompleted ? "item_completed" : "item_uncompleted";
          details = {
            itemName: after.name,
            itemId: itemId,
          };
          userId = after.isCompleted ? (after.completedBy || after.addedBy) : after.addedBy;
          userName = after.isCompleted ? (after.completedByName || after.addedByName) : after.addedByName;
        } else {
          activityType = "item_updated";
          details = {
            itemName: after.name,
            itemId: itemId,
          };
          userId = after.addedBy;
          userName = after.addedByName;
        }
      }
      
      if (activityType && userId) {
        await db
          .collection("lists")
          .doc(listId)
          .collection("activity")
          .add({
            type: activityType,
            userId: userId,
            userName: userName,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: details,
          });
        
        functions.logger.info(`Logged activity: ${activityType} for list ${listId}`);
      }
    } catch (error) {
      functions.logger.error("Error logging activity:", error);
    }
  });

// Accept invitation function
export const acceptInvitation = functions.https.onCall(async (data, context): Promise<{ success: boolean }> => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }
  
  const { invitationId } = data as { invitationId: string };
  
  if (!invitationId) {
    throw new functions.https.HttpsError("invalid-argument", "Invitation ID is required");
  }
  
  const userId = context.auth.uid;
  const userEmail = context.auth.token.email;
  
  if (!userEmail) {
    throw new functions.https.HttpsError("failed-precondition", "User email is required");
  }
  
  try {
    const invitationDoc = await db.collection("invitations").doc(invitationId).get();
    
    if (!invitationDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Invitation not found");
    }
    
    const invitation = invitationDoc.data() as InvitationData;
    
    if (invitation.invitedEmail !== userEmail) {
      throw new functions.https.HttpsError("permission-denied", "Invitation not for this email");
    }
    
    if (invitation.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Invitation already processed");
    }
    
    if (invitation.expiresAt.toDate() < new Date()) {
      throw new functions.https.HttpsError("failed-precondition", "Invitation has expired");
    }
    
    // Get user display name
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data() as UserData | undefined;
    const displayName = userData?.displayName || userEmail;
    
    // Run transaction to ensure consistency
    await db.runTransaction(async (transaction) => {
      // Add user to list members
      const listRef = db.collection("lists").doc(invitation.listId);
      transaction.update(listRef, {
        [`members.${userId}`]: {
          role: invitation.role,
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          displayName: displayName,
        },
      });
      
      // Update invitation status
      const invitationRef = db.collection("invitations").doc(invitationId);
      transaction.update(invitationRef, {
        status: "accepted",
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
        acceptedBy: userId,
      });
    });
    
    functions.logger.info(`User ${userId} accepted invitation ${invitationId} for list ${invitation.listId}`);
    return { success: true };
  } catch (error) {
    functions.logger.error("Error accepting invitation:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "An unexpected error occurred");
  }
});

// Helper function to clean up invalid FCM tokens
async function cleanupInvalidTokens(userIds: string[], invalidTokens: string[]): Promise<void> {
  if (invalidTokens.length === 0) return;
  
  try {
    const batch = db.batch();
    
    for (const userId of userIds) {
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens)
      });
    }
    
    await batch.commit();
    functions.logger.info(`Cleaned up ${invalidTokens.length} invalid FCM tokens`);
  } catch (error) {
    functions.logger.error("Error cleaning up invalid tokens:", error);
  }
}
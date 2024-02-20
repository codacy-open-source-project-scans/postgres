/*-------------------------------------------------------------------------
 *
 * slotsync.h
 *	  Exports for slot synchronization.
 *
 * Portions Copyright (c) 2016-2024, PostgreSQL Global Development Group
 *
 * src/include/replication/slotsync.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef SLOTSYNC_H
#define SLOTSYNC_H

#include "replication/walreceiver.h"

extern void ValidateSlotSyncParams(void);
extern bool IsSyncingReplicationSlots(void);
extern Size SlotSyncShmemSize(void);
extern void SlotSyncShmemInit(void);
extern void SyncReplicationSlots(WalReceiverConn *wrconn);

#endif							/* SLOTSYNC_H */

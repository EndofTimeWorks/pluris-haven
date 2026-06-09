import { relations } from 'drizzle-orm';
import {
	boolean,
	customType,
	index,
	jsonb,
	pgTable,
	text,
	timestamp,
	uniqueIndex,
	uuid
} from 'drizzle-orm/pg-core';

const bytea = customType<{ data: Buffer; driverData: Buffer }>({
	dataType() {
		return 'bytea';
	}
});

const createdAt = timestamp('created_at', { withTimezone: true }).notNull().defaultNow();
const updatedAt = timestamp('updated_at', { withTimezone: true }).notNull().defaultNow();

export const users = pgTable('users', {
	id: uuid('id').defaultRandom().primaryKey(),
	email: text('email').unique(),
	displayName: text('display_name'),
	createdAt
});

export const systems = pgTable(
	'systems',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
		displayName: text('display_name').notNull(),
		language: text('language').notNull().default('en'),
		currentFrontLabel: text('current_front_label'),
		createdAt,
		updatedAt
	},
	(table) => [uniqueIndex('systems_user_id_idx').on(table.userId)]
);

export const folders = pgTable(
	'folders',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		parentFolderId: uuid('parent_folder_id'),
		name: text('name').notNull(),
		kind: text('kind').notNull(),
		createdAt
	},
	(table) => [index('folders_system_kind_idx').on(table.systemId, table.kind)]
);

export const members = pgTable(
	'members',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		folderId: uuid('folder_id').references(() => folders.id, { onDelete: 'set null' }),
		displayName: text('display_name').notNull(),
		avatarUrl: text('avatar_url'),
		pronouns: text('pronouns'),
		color: text('color'),
		archived: boolean('archived').notNull().default(false),
		createdAt,
		updatedAt
	},
	(table) => [index('members_system_idx').on(table.systemId)]
);

export const customTerms = pgTable(
	'custom_terms',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		key: text('key').notNull(),
		value: text('value').notNull(),
		language: text('language').notNull().default('en')
	},
	(table) => [uniqueIndex('custom_terms_system_key_language_idx').on(table.systemId, table.key, table.language)]
);

export const frontStates = pgTable(
	'front_states',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		name: text('name').notNull(),
		color: text('color'),
		isDefault: boolean('is_default').notNull().default(false)
	},
	(table) => [index('front_states_system_idx').on(table.systemId)]
);

export const frontEvents = pgTable(
	'front_events',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		memberId: uuid('member_id').references(() => members.id, { onDelete: 'set null' }),
		frontStateId: uuid('front_state_id').references(() => frontStates.id, { onDelete: 'set null' }),
		startedAt: timestamp('started_at', { withTimezone: true }).notNull(),
		endedAt: timestamp('ended_at', { withTimezone: true }),
		noteCiphertext: bytea('note_ciphertext'),
		noteIv: bytea('note_iv'),
		source: text('source').notNull().default('local')
	},
	(table) => [index('front_events_system_started_idx').on(table.systemId, table.startedAt)]
);

export const logs = pgTable(
	'logs',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		memberId: uuid('member_id').references(() => members.id, { onDelete: 'set null' }),
		kind: text('kind').notNull(),
		occurredAt: timestamp('occurred_at', { withTimezone: true }).notNull().defaultNow(),
		title: text('title'),
		bodyCiphertext: bytea('body_ciphertext'),
		bodyIv: bytea('body_iv'),
		metadata: jsonb('metadata').$type<Record<string, unknown>>()
	},
	(table) => [index('logs_system_occurred_idx').on(table.systemId, table.occurredAt)]
);

export const chats = pgTable(
	'chats',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		folderId: uuid('folder_id').references(() => folders.id, { onDelete: 'set null' }),
		title: text('title').notNull(),
		archived: boolean('archived').notNull().default(false),
		createdAt
	},
	(table) => [index('chats_system_idx').on(table.systemId)]
);

export const chatMessages = pgTable(
	'chat_messages',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		chatId: uuid('chat_id')
			.notNull()
			.references(() => chats.id, { onDelete: 'cascade' }),
		memberId: uuid('member_id').references(() => members.id, { onDelete: 'set null' }),
		sentAt: timestamp('sent_at', { withTimezone: true }).notNull().defaultNow(),
		bodyCiphertext: bytea('body_ciphertext'),
		bodyIv: bytea('body_iv'),
		source: text('source').notNull().default('local')
	},
	(table) => [index('chat_messages_chat_sent_idx').on(table.chatId, table.sentAt)]
);

export const journalEntries = pgTable(
	'journal_entries',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		memberId: uuid('member_id').references(() => members.id, { onDelete: 'set null' }),
		folderId: uuid('folder_id').references(() => folders.id, { onDelete: 'set null' }),
		createdAt,
		titleCiphertext: bytea('title_ciphertext'),
		titleIv: bytea('title_iv'),
		contentCiphertext: bytea('content_ciphertext').notNull(),
		contentIv: bytea('content_iv').notNull(),
		archived: boolean('archived').notNull().default(false)
	},
	(table) => [index('journal_entries_system_created_idx').on(table.systemId, table.createdAt)]
);

export const polls = pgTable(
	'polls',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		folderId: uuid('folder_id').references(() => folders.id, { onDelete: 'set null' }),
		questionCiphertext: bytea('question_ciphertext').notNull(),
		questionIv: bytea('question_iv').notNull(),
		optionsCiphertext: bytea('options_ciphertext').notNull(),
		optionsIv: bytea('options_iv').notNull(),
		status: text('status').notNull().default('open'),
		createdAt,
		closedAt: timestamp('closed_at', { withTimezone: true })
	},
	(table) => [index('polls_system_status_idx').on(table.systemId, table.status)]
);

export const pollVotes = pgTable(
	'poll_votes',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		pollId: uuid('poll_id')
			.notNull()
			.references(() => polls.id, { onDelete: 'cascade' }),
		memberId: uuid('member_id').references(() => members.id, { onDelete: 'set null' }),
		optionKey: text('option_key').notNull(),
		createdAt
	},
	(table) => [uniqueIndex('poll_votes_poll_member_idx').on(table.pollId, table.memberId)]
);

export const friends = pgTable(
	'friends',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		friendSystemId: uuid('friend_system_id').references(() => systems.id, { onDelete: 'cascade' }),
		displayName: text('display_name').notNull(),
		status: text('status').notNull().default('pending'),
		shareLevel: text('share_level').notNull().default('front_only'),
		createdAt
	},
	(table) => [index('friends_system_status_idx').on(table.systemId, table.status)]
);

export const serviceConnections = pgTable(
	'service_connections',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		service: text('service').notNull(),
		displayName: text('display_name').notNull(),
		disclaimerAcceptedAt: timestamp('disclaimer_accepted_at', { withTimezone: true }),
		encryptedToken: bytea('encrypted_token'),
		tokenIv: bytea('token_iv'),
		settings: jsonb('settings').$type<Record<string, unknown>>(),
		createdAt
	},
	(table) => [uniqueIndex('service_connections_system_service_idx').on(table.systemId, table.service)]
);

export const importJobs = pgTable(
	'import_jobs',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		source: text('source').notNull(),
		status: text('status').notNull().default('queued'),
		summary: jsonb('summary').$type<Record<string, unknown>>(),
		createdAt,
		completedAt: timestamp('completed_at', { withTimezone: true })
	},
	(table) => [index('import_jobs_system_source_idx').on(table.systemId, table.source)]
);

export const exportJobs = pgTable(
	'export_jobs',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		status: text('status').notNull().default('queued'),
		format: text('format').notNull().default('json'),
		createdAt,
		completedAt: timestamp('completed_at', { withTimezone: true })
	},
	(table) => [index('export_jobs_system_status_idx').on(table.systemId, table.status)]
);

export const archives = pgTable(
	'archives',
	{
		id: uuid('id').defaultRandom().primaryKey(),
		systemId: uuid('system_id')
			.notNull()
			.references(() => systems.id, { onDelete: 'cascade' }),
		itemType: text('item_type').notNull(),
		itemId: uuid('item_id').notNull(),
		reasonCiphertext: bytea('reason_ciphertext'),
		reasonIv: bytea('reason_iv'),
		createdAt
	},
	(table) => [index('archives_system_type_idx').on(table.systemId, table.itemType)]
);

export const usersRelations = relations(users, ({ many }) => ({
	systems: many(systems)
}));

export const systemsRelations = relations(systems, ({ one, many }) => ({
	user: one(users, { fields: [systems.userId], references: [users.id] }),
	folders: many(folders),
	members: many(members),
	frontEvents: many(frontEvents),
	logs: many(logs),
	chats: many(chats),
	journalEntries: many(journalEntries),
	polls: many(polls),
	friends: many(friends),
	serviceConnections: many(serviceConnections),
	importJobs: many(importJobs),
	exportJobs: many(exportJobs),
	archives: many(archives)
}));

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type System = typeof systems.$inferSelect;
export type NewSystem = typeof systems.$inferInsert;

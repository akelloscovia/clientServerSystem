import { z } from 'zod';

// zod schemas mirroring the old marshmallow schemas in app/schemas/*.
// `.parse()` throws a ZodError, which the error middleware turns into
// `422 { errors: { field: [messages] } }`.

const email = z.string().email();

export const registerSchema = z.object({
  name: z.string().min(2).max(120),
  email,
  password: z
    .string()
    .min(8)
    .max(128)
    .refine((v) => /[A-Z]/.test(v), 'Password must contain at least one uppercase letter.')
    .refine((v) => /[0-9]/.test(v), 'Password must contain at least one digit.'),
});

export const loginSchema = z.object({
  email,
  password: z.string().min(1),
});

const CATEGORIES = ['complaint', 'inquiry', 'report', 'request', 'other'];
const PRIORITIES = ['low', 'medium', 'high', 'urgent'];
const SUB_STATUSES = ['pending', 'under_review', 'assigned', 'resolved', 'closed'];

export const submissionCreateSchema = z.object({
  title: z.string().min(5).max(200),
  description: z.string().min(10),
  category: z.enum(CATEGORIES).default('other'),
  priority: z.enum(PRIORITIES).default('medium'),
});

export const submissionUpdateSchema = z.object({
  status: z.enum(SUB_STATUSES),
});

export const assignmentSchema = z.object({
  submission_id: z.coerce.number().int(),
  assigned_to: z.coerce.number().int(),
  notes: z.string().default(''),
});

export const responseCreateSchema = z.object({
  submission_id: z.coerce.number().int(),
  message: z.string().min(1).max(5000),
});

const DAYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'daily'];
const HHMM = /^\d{1,2}:\d{2}(?::\d{2})?$/;

export const programSchema = z.object({
  title: z.string().min(2).max(200),
  description: z.string().nullish().transform((v) => v ?? ''),
  day: z.enum(DAYS).default('daily'),
  start_time: z.string().regex(HHMM, 'Not a valid time.'),
  end_time: z.string().regex(HHMM, 'Not a valid time.'),
  location: z.string().max(200).nullish().transform((v) => v ?? null),
  is_active: z.boolean().default(true),
});

const STREAM_TYPES = ['hls', 'youtube', 'mp4', 'other'];

export const channelSchema = z.object({
  name: z.string().min(1).max(100),
  stream_url: z.string().min(5).max(500),
  logo_url: z.string().max(500).nullish().transform((v) => v ?? ''),
  stream_type: z.enum(STREAM_TYPES).default('hls'),
  sort_order: z.coerce.number().int().default(0),
  is_active: z.boolean().default(true),
});

const VISITOR_STATUSES = ['pending', 'assigned', 'attended', 'closed'];

export const visitorCreateSchema = z.object({
  name: z.string().min(2).max(150),
  company: z.string().max(150).nullish().transform((v) => v ?? ''),
  visit_date: z.string().regex(/^\d{4}-\d{2}-\d{2}/, 'Not a valid date.'),
  time_in: z.string().regex(HHMM, 'Not a valid time.'),
  reason_for_visit: z.string().min(3).max(300),
  description: z.string().nullish().transform((v) => v ?? ''),
});

export const visitorStatusSchema = z.object({
  status: z.enum(VISITOR_STATUSES),
});

export const visitorAssignSchema = z.object({
  assigned_to: z.coerce.number().int(),
});

export const visitorReplySchema = z.object({
  message: z.string().min(1),
});

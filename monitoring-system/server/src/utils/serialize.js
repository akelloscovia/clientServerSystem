import { isoNaiveUTC, hhmm, ymd } from './dates.js';

// Each function reproduces the corresponding old `Model.to_dict()` exactly —
// same keys, same order, same derived fields. Relations must be `include`d by
// the caller where a name/role is needed.

export function userDict(u) {
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    role: u.role,
    is_active: u.is_active,
    created_at: isoNaiveUTC(u.created_at),
  };
}

export function responseDict(r) {
  return {
    id: r.id,
    submission_id: r.submission_id,
    responder_id: r.responder_id,
    responder: r.responder ? r.responder.name : null,
    responder_role: r.responder ? r.responder.role : null,
    message: r.message,
    created_at: isoNaiveUTC(r.created_at),
  };
}

export function statusHistoryDict(h) {
  return {
    id: h.id,
    submission_id: h.submission_id,
    changed_by: h.changed_by,
    actor: h.actor ? h.actor.name : 'System',
    from_status: h.from_status,
    to_status: h.to_status,
    changed_at: isoNaiveUTC(h.changed_at),
  };
}

export function submissionDict(s, { includeResponses = false } = {}) {
  const data = {
    id: s.id,
    user_id: s.user_id,
    submitter: s.submitter ? s.submitter.name : null,
    title: s.title,
    description: s.description,
    category: s.category,
    priority: s.priority,
    status: s.status,
    created_at: isoNaiveUTC(s.created_at),
    updated_at: isoNaiveUTC(s.updated_at),
  };
  if (includeResponses) {
    data.responses = (s.responses || []).map(responseDict);
    data.status_history = (s.status_history || []).map(statusHistoryDict);
  }
  return data;
}

export function assignmentDict(a) {
  return {
    id: a.id,
    submission_id: a.submission_id,
    assigned_to: a.assigned_to,
    secretary: a.secretary ? a.secretary.name : null,
    assigned_by: a.assigned_by,
    admin: a.admin ? a.admin.name : null,
    notes: a.notes,
    assigned_at: isoNaiveUTC(a.assigned_at),
  };
}

export function auditLogDict(l) {
  return {
    id: l.id,
    user_id: l.user_id,
    actor: l.actor ? l.actor.name : 'System',
    action: l.action,
    entity_type: l.entity_type,
    entity_id: l.entity_id,
    details: l.details,
    ip_address: l.ip_address,
    timestamp: isoNaiveUTC(l.timestamp),
  };
}

export function notificationDict(n) {
  return {
    id: n.id,
    user_id: n.user_id,
    submission_id: n.submission_id,
    message: n.message,
    is_read: n.is_read,
    created_at: isoNaiveUTC(n.created_at),
  };
}

export function channelDict(c) {
  return {
    id: c.id,
    name: c.name,
    stream_url: c.stream_url,
    logo_url: c.logo_url,
    stream_type: c.stream_type,
    sort_order: c.sort_order,
    is_active: c.is_active,
    created_at: isoNaiveUTC(c.created_at),
    updated_at: isoNaiveUTC(c.updated_at),
  };
}

export function programDict(p) {
  return {
    id: p.id,
    title: p.title,
    description: p.description,
    day: p.day,
    start_time: hhmm(p.start_time),
    end_time: hhmm(p.end_time),
    location: p.location,
    is_active: p.is_active,
    created_at: isoNaiveUTC(p.created_at),
    updated_at: isoNaiveUTC(p.updated_at),
  };
}

export function visitorReplyDict(r) {
  return {
    id: r.id,
    visitor_id: r.visitor_id,
    responder_id: r.responder_id,
    responder: r.responder ? r.responder.name : null,
    message: r.message,
    created_at: isoNaiveUTC(r.created_at),
  };
}

export function visitorDict(v, { includeReplies = false } = {}) {
  const data = {
    id: v.id,
    name: v.name,
    company: v.company,
    visit_date: ymd(v.visit_date),
    time_in: hhmm(v.time_in),
    reason_for_visit: v.reason_for_visit,
    description: v.description,
    status: v.status,
    assigned_to: v.assigned_to,
    assignee: v.assigned_user ? v.assigned_user.name : null,
    assigned_by: v.assigned_by,
    assigned_at: isoNaiveUTC(v.assigned_at),
    created_at: isoNaiveUTC(v.created_at),
    updated_at: isoNaiveUTC(v.updated_at),
  };
  if (includeReplies) {
    data.replies = (v.replies || []).map(visitorReplyDict);
  }
  return data;
}

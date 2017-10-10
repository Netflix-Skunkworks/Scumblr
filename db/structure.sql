--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.7
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE comments (
    id integer NOT NULL,
    commentable_id integer DEFAULT 0,
    commentable_type character varying(255) DEFAULT ''::character varying,
    title character varying(255) DEFAULT ''::character varying,
    body text,
    subject character varying(255) DEFAULT ''::character varying,
    user_id integer DEFAULT 0 NOT NULL,
    parent_id integer,
    lft integer,
    rgt integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: event_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE event_changes (
    id integer NOT NULL,
    event_id integer,
    field character varying(255),
    new_value text,
    old_value text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    old_value_key integer,
    new_value_key integer,
    value_class character varying(255)
);


--
-- Name: event_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_changes_id_seq OWNED BY event_changes.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE events (
    id integer NOT NULL,
    action character varying(255),
    source character varying(255),
    details text,
    date timestamp without time zone,
    user_id integer,
    eventable_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    eventable_type character varying(255)
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE flags (
    id integer NOT NULL,
    name character varying(255),
    color character varying(255),
    workflow_id integer,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flags_id_seq OWNED BY flags.id;


--
-- Name: result_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE result_attachments (
    id integer NOT NULL,
    result_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    attachment_file_name character varying(255),
    attachment_content_type character varying(255),
    attachment_file_size integer,
    attachment_updated_at timestamp without time zone,
    attachment_fingerprint character varying(255)
);


--
-- Name: result_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE result_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE result_attachments_id_seq OWNED BY result_attachments.id;


--
-- Name: result_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE result_flags (
    id integer NOT NULL,
    stage_id integer,
    workflow_id integer,
    flag_id integer,
    result_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: result_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE result_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE result_flags_id_seq OWNED BY result_flags.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE results (
    id integer NOT NULL,
    title character varying(255),
    url character varying(255),
    status_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    domain character varying(255),
    user_id integer,
    content text,
    metadata_archive text,
    metadata jsonb,
    metadata_hash character varying(255)
);


--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE results_id_seq OWNED BY results.id;


--
-- Name: saved_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE saved_filters (
    id integer NOT NULL,
    name character varying(255),
    query text,
    user_id integer,
    public boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    saved_filter_type character varying(255),
    store_index_columns boolean,
    index_columns text
);


--
-- Name: saved_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE saved_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: saved_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE saved_filters_id_seq OWNED BY saved_filters.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE statuses (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    closed boolean,
    is_invalid boolean,
    "default" boolean DEFAULT false
);


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE statuses_id_seq OWNED BY statuses.id;


--
-- Name: subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE subscribers (
    id integer NOT NULL,
    subscribable_id integer,
    subscribable_type character varying(255),
    email character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subscribers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscribers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscribers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscribers_id_seq OWNED BY subscribers.id;


--
-- Name: summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE summaries (
    id integer NOT NULL,
    summarizable_id integer,
    summarizable_type character varying(255),
    "timestamp" timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE summaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE summaries_id_seq OWNED BY summaries.id;


--
-- Name: system_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE system_metadata (
    id integer NOT NULL,
    key character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    metadata jsonb
);


--
-- Name: system_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE system_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE system_metadata_id_seq OWNED BY system_metadata.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    taggable_type character varying(255)
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255),
    color character varying(255),
    value character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: task_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE task_results (
    id integer NOT NULL,
    result_id integer,
    task_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: task_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE task_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE task_results_id_seq OWNED BY task_results.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tasks (
    id integer NOT NULL,
    task_type character varying(255),
    options text,
    name character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    query text,
    enabled boolean DEFAULT true,
    "group" integer DEFAULT 1,
    metadata jsonb,
    run_type character varying DEFAULT 'scheduled'::character varying,
    frequency character varying DEFAULT ''::character varying
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;


--
-- Name: user_saved_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_saved_filters (
    id integer NOT NULL,
    user_id integer,
    saved_filter_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_saved_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_saved_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_saved_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_saved_filters_id_seq OWNED BY user_saved_filters.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    provider character varying(255),
    uid character varying(255),
    admin boolean DEFAULT false,
    disabled boolean DEFAULT false,
    first_name character varying(255),
    last_name character varying(255),
    thumbnail text,
    metadata jsonb
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: workflowable_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_actions (
    id integer NOT NULL,
    name character varying(255),
    options text,
    action_plugin character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" integer
);


--
-- Name: workflowable_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_actions_id_seq OWNED BY workflowable_actions.id;


--
-- Name: workflowable_stage_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_stage_actions (
    id integer NOT NULL,
    stage_id integer,
    action_id integer,
    event character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: workflowable_stage_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_stage_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_stage_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_stage_actions_id_seq OWNED BY workflowable_stage_actions.id;


--
-- Name: workflowable_stage_next_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_stage_next_steps (
    id integer NOT NULL,
    current_stage_id integer,
    next_stage_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: workflowable_stage_next_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_stage_next_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_stage_next_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_stage_next_steps_id_seq OWNED BY workflowable_stage_next_steps.id;


--
-- Name: workflowable_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_stages (
    id integer NOT NULL,
    name character varying(255),
    workflow_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: workflowable_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_stages_id_seq OWNED BY workflowable_stages.id;


--
-- Name: workflowable_workflow_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_workflow_actions (
    id integer NOT NULL,
    workflow_id integer,
    action_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: workflowable_workflow_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_workflow_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_workflow_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_workflow_actions_id_seq OWNED BY workflowable_workflow_actions.id;


--
-- Name: workflowable_workflows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflowable_workflows (
    id integer NOT NULL,
    name character varying(255),
    initial_stage_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: workflowable_workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflowable_workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflowable_workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflowable_workflows_id_seq OWNED BY workflowable_workflows.id;


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: event_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_changes ALTER COLUMN id SET DEFAULT nextval('event_changes_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flags ALTER COLUMN id SET DEFAULT nextval('flags_id_seq'::regclass);


--
-- Name: result_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY result_attachments ALTER COLUMN id SET DEFAULT nextval('result_attachments_id_seq'::regclass);


--
-- Name: result_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY result_flags ALTER COLUMN id SET DEFAULT nextval('result_flags_id_seq'::regclass);


--
-- Name: results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY results ALTER COLUMN id SET DEFAULT nextval('results_id_seq'::regclass);


--
-- Name: saved_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY saved_filters ALTER COLUMN id SET DEFAULT nextval('saved_filters_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses ALTER COLUMN id SET DEFAULT nextval('statuses_id_seq'::regclass);


--
-- Name: subscribers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscribers ALTER COLUMN id SET DEFAULT nextval('subscribers_id_seq'::regclass);


--
-- Name: summaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY summaries ALTER COLUMN id SET DEFAULT nextval('summaries_id_seq'::regclass);


--
-- Name: system_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY system_metadata ALTER COLUMN id SET DEFAULT nextval('system_metadata_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: task_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY task_results ALTER COLUMN id SET DEFAULT nextval('task_results_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: user_saved_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_saved_filters ALTER COLUMN id SET DEFAULT nextval('user_saved_filters_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: workflowable_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_actions ALTER COLUMN id SET DEFAULT nextval('workflowable_actions_id_seq'::regclass);


--
-- Name: workflowable_stage_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stage_actions ALTER COLUMN id SET DEFAULT nextval('workflowable_stage_actions_id_seq'::regclass);


--
-- Name: workflowable_stage_next_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stage_next_steps ALTER COLUMN id SET DEFAULT nextval('workflowable_stage_next_steps_id_seq'::regclass);


--
-- Name: workflowable_stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stages ALTER COLUMN id SET DEFAULT nextval('workflowable_stages_id_seq'::regclass);


--
-- Name: workflowable_workflow_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_workflow_actions ALTER COLUMN id SET DEFAULT nextval('workflowable_workflow_actions_id_seq'::regclass);


--
-- Name: workflowable_workflows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_workflows ALTER COLUMN id SET DEFAULT nextval('workflowable_workflows_id_seq'::regclass);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: event_changes event_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_changes
    ADD CONSTRAINT event_changes_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: flags flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flags
    ADD CONSTRAINT flags_pkey PRIMARY KEY (id);


--
-- Name: result_attachments result_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY result_attachments
    ADD CONSTRAINT result_attachments_pkey PRIMARY KEY (id);


--
-- Name: result_flags result_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY result_flags
    ADD CONSTRAINT result_flags_pkey PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: saved_filters saved_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY saved_filters
    ADD CONSTRAINT saved_filters_pkey PRIMARY KEY (id);


--
-- Name: task_results search_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY task_results
    ADD CONSTRAINT search_results_pkey PRIMARY KEY (id);


--
-- Name: tasks searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT searches_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: subscribers subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscribers
    ADD CONSTRAINT subscribers_pkey PRIMARY KEY (id);


--
-- Name: summaries summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY summaries
    ADD CONSTRAINT summaries_pkey PRIMARY KEY (id);


--
-- Name: system_metadata system_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY system_metadata
    ADD CONSTRAINT system_metadata_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: user_saved_filters user_saved_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_saved_filters
    ADD CONSTRAINT user_saved_filters_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workflowable_actions workflowable_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_actions
    ADD CONSTRAINT workflowable_actions_pkey PRIMARY KEY (id);


--
-- Name: workflowable_stage_actions workflowable_stage_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stage_actions
    ADD CONSTRAINT workflowable_stage_actions_pkey PRIMARY KEY (id);


--
-- Name: workflowable_stage_next_steps workflowable_stage_next_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stage_next_steps
    ADD CONSTRAINT workflowable_stage_next_steps_pkey PRIMARY KEY (id);


--
-- Name: workflowable_stages workflowable_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_stages
    ADD CONSTRAINT workflowable_stages_pkey PRIMARY KEY (id);


--
-- Name: workflowable_workflow_actions workflowable_workflow_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_workflow_actions
    ADD CONSTRAINT workflowable_workflow_actions_pkey PRIMARY KEY (id);


--
-- Name: workflowable_workflows workflowable_workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflowable_workflows
    ADD CONSTRAINT workflowable_workflows_pkey PRIMARY KEY (id);


--
-- Name: index_comments_on_commentable_id_and_commentable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_id_and_commentable_type ON comments USING btree (commentable_id, commentable_type);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON comments USING btree (user_id);


--
-- Name: index_event_changes_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_changes_on_event_id ON event_changes USING btree (event_id);


--
-- Name: index_event_changes_on_field; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_changes_on_field ON event_changes USING btree (field);


--
-- Name: index_events_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_action ON events USING btree (action);


--
-- Name: index_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_created_at ON events USING btree (created_at);


--
-- Name: index_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_eventable_id ON events USING btree (eventable_id);


--
-- Name: index_events_on_eventable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_eventable_type ON events USING btree (eventable_type);


--
-- Name: index_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_user_id ON events USING btree (user_id);


--
-- Name: index_result_attachments_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_attachments_on_result_id ON result_attachments USING btree (result_id);


--
-- Name: index_result_flags_on_flag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_flags_on_flag_id ON result_flags USING btree (flag_id);


--
-- Name: index_result_flags_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_result_flags_on_result_id ON result_flags USING btree (result_id);


--
-- Name: index_results_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_results_on_status_id ON results USING btree (status_id);


--
-- Name: index_saved_filters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_filters_on_user_id ON saved_filters USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_taggings_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_result_id ON taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_task_results_on_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_task_results_on_result_id ON task_results USING btree (result_id);


--
-- Name: index_task_results_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_task_results_on_task_id ON task_results USING btree (task_id);


--
-- Name: index_user_saved_filters_on_saved_filter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_saved_filters_on_saved_filter_id ON user_saved_filters USING btree (saved_filter_id);


--
-- Name: index_user_saved_filters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_saved_filters_on_user_id ON user_saved_filters USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_workflowable_stage_actions_on_action_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflowable_stage_actions_on_action_id ON workflowable_stage_actions USING btree (action_id);


--
-- Name: index_workflowable_stage_actions_on_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflowable_stage_actions_on_stage_id ON workflowable_stage_actions USING btree (stage_id);


--
-- Name: index_workflowable_stages_on_workflow_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflowable_stages_on_workflow_id ON workflowable_stages USING btree (workflow_id);


--
-- Name: index_workflowable_workflow_actions_on_action_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflowable_workflow_actions_on_action_id ON workflowable_workflow_actions USING btree (action_id);


--
-- Name: index_workflowable_workflow_actions_on_workflow_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflowable_workflow_actions_on_workflow_id ON workflowable_workflow_actions USING btree (workflow_id);


--
-- Name: unique_results; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_results ON results USING btree (url);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: unique_search_results; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_search_results ON task_results USING btree (task_id, result_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20140116225320');

INSERT INTO schema_migrations (version) VALUES ('20140116230348');

INSERT INTO schema_migrations (version) VALUES ('20140303185937');

INSERT INTO schema_migrations (version) VALUES ('20140311154531');

INSERT INTO schema_migrations (version) VALUES ('20140311180003');

INSERT INTO schema_migrations (version) VALUES ('20140311181057');

INSERT INTO schema_migrations (version) VALUES ('20140311223343');

INSERT INTO schema_migrations (version) VALUES ('20140311232843');

INSERT INTO schema_migrations (version) VALUES ('20140311233611');

INSERT INTO schema_migrations (version) VALUES ('20140312014829');

INSERT INTO schema_migrations (version) VALUES ('20140312014958');

INSERT INTO schema_migrations (version) VALUES ('20140313003238');

INSERT INTO schema_migrations (version) VALUES ('20140319003839');

INSERT INTO schema_migrations (version) VALUES ('20140320154956');

INSERT INTO schema_migrations (version) VALUES ('20140320155157');

INSERT INTO schema_migrations (version) VALUES ('20140321165314');

INSERT INTO schema_migrations (version) VALUES ('20140324211908');

INSERT INTO schema_migrations (version) VALUES ('20140325175623');

INSERT INTO schema_migrations (version) VALUES ('20140422210107');

INSERT INTO schema_migrations (version) VALUES ('20140422210149');

INSERT INTO schema_migrations (version) VALUES ('20140422223956');

INSERT INTO schema_migrations (version) VALUES ('20140422223957');

INSERT INTO schema_migrations (version) VALUES ('20140422223958');

INSERT INTO schema_migrations (version) VALUES ('20140422223959');

INSERT INTO schema_migrations (version) VALUES ('20140422223960');

INSERT INTO schema_migrations (version) VALUES ('20140422223961');

INSERT INTO schema_migrations (version) VALUES ('20140422223962');

INSERT INTO schema_migrations (version) VALUES ('20140425230055');

INSERT INTO schema_migrations (version) VALUES ('20140501180819');

INSERT INTO schema_migrations (version) VALUES ('20140520180511');

INSERT INTO schema_migrations (version) VALUES ('20140708174418');

INSERT INTO schema_migrations (version) VALUES ('20140922200437');

INSERT INTO schema_migrations (version) VALUES ('20140922200438');

INSERT INTO schema_migrations (version) VALUES ('20150324190835');

INSERT INTO schema_migrations (version) VALUES ('20150526174549');

INSERT INTO schema_migrations (version) VALUES ('20150528174243');

INSERT INTO schema_migrations (version) VALUES ('20150528201240');

INSERT INTO schema_migrations (version) VALUES ('20150603213217');

INSERT INTO schema_migrations (version) VALUES ('20150603213235');

INSERT INTO schema_migrations (version) VALUES ('20150609203000');

INSERT INTO schema_migrations (version) VALUES ('20150609203030');

INSERT INTO schema_migrations (version) VALUES ('20150610174010');

INSERT INTO schema_migrations (version) VALUES ('20150611181533');

INSERT INTO schema_migrations (version) VALUES ('20150626175252');

INSERT INTO schema_migrations (version) VALUES ('20150727171144');

INSERT INTO schema_migrations (version) VALUES ('20150727201922');

INSERT INTO schema_migrations (version) VALUES ('20150803212059');

INSERT INTO schema_migrations (version) VALUES ('20151216190245');

INSERT INTO schema_migrations (version) VALUES ('20160115230746');

INSERT INTO schema_migrations (version) VALUES ('20160218172906');

INSERT INTO schema_migrations (version) VALUES ('20160629192755');

INSERT INTO schema_migrations (version) VALUES ('20160804194709');

INSERT INTO schema_migrations (version) VALUES ('20170517173248');

INSERT INTO schema_migrations (version) VALUES ('20170612211157');

INSERT INTO schema_migrations (version) VALUES ('20170622205314');

INSERT INTO schema_migrations (version) VALUES ('20170705165950');

INSERT INTO schema_migrations (version) VALUES ('20170714205623');


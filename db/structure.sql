--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Debian 16.4-1.pgdg110+2)
-- Dumped by pg_dump version 16.4 (Debian 16.4-1.pgdg110+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger;


--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tiger_data;


--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA topology;


--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: country_boundaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country_boundaries (
    id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying,
    geometry public.geography(Polygon,4326),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: country_boundaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.country_boundaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: country_boundaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.country_boundaries_id_seq OWNED BY public.country_boundaries.id;


--
-- Name: forest_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.forest_areas (
    id bigint NOT NULL,
    osm_id character varying,
    name character varying,
    forest_type character varying,
    geometry public.geography,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: forest_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.forest_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forest_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.forest_areas_id_seq OWNED BY public.forest_areas.id;


--
-- Name: military_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.military_areas (
    id bigint NOT NULL,
    name character varying NOT NULL,
    osm_id character varying,
    geometry public.geography(Polygon,4326),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: military_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.military_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: military_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.military_areas_id_seq OWNED BY public.military_areas.id;


--
-- Name: protected_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protected_areas (
    id bigint NOT NULL,
    name character varying NOT NULL,
    protect_class character varying,
    protection_title character varying,
    country character varying DEFAULT 'CZ'::character varying,
    osm_id character varying,
    geometry public.geography,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: protected_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protected_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protected_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.protected_areas_id_seq OWNED BY public.protected_areas.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: country_boundaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_boundaries ALTER COLUMN id SET DEFAULT nextval('public.country_boundaries_id_seq'::regclass);


--
-- Name: forest_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forest_areas ALTER COLUMN id SET DEFAULT nextval('public.forest_areas_id_seq'::regclass);


--
-- Name: military_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.military_areas ALTER COLUMN id SET DEFAULT nextval('public.military_areas_id_seq'::regclass);


--
-- Name: protected_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_areas ALTER COLUMN id SET DEFAULT nextval('public.protected_areas_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: country_boundaries country_boundaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_boundaries
    ADD CONSTRAINT country_boundaries_pkey PRIMARY KEY (id);


--
-- Name: forest_areas forest_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.forest_areas
    ADD CONSTRAINT forest_areas_pkey PRIMARY KEY (id);


--
-- Name: military_areas military_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.military_areas
    ADD CONSTRAINT military_areas_pkey PRIMARY KEY (id);


--
-- Name: protected_areas protected_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_areas
    ADD CONSTRAINT protected_areas_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_country_boundaries_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_boundaries_on_code ON public.country_boundaries USING btree (code);


--
-- Name: index_country_boundaries_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_country_boundaries_on_geometry ON public.country_boundaries USING gist (geometry);


--
-- Name: index_forest_areas_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_forest_areas_on_geometry ON public.forest_areas USING gist (geometry);


--
-- Name: index_forest_areas_on_osm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_forest_areas_on_osm_id ON public.forest_areas USING btree (osm_id);


--
-- Name: index_military_areas_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_military_areas_on_geometry ON public.military_areas USING gist (geometry);


--
-- Name: index_military_areas_on_osm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_military_areas_on_osm_id ON public.military_areas USING btree (osm_id);


--
-- Name: index_protected_areas_on_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_areas_on_country ON public.protected_areas USING btree (country);


--
-- Name: index_protected_areas_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_areas_on_geometry ON public.protected_areas USING gist (geometry);


--
-- Name: index_protected_areas_on_osm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_protected_areas_on_osm_id ON public.protected_areas USING btree (osm_id);


--
-- Name: index_protected_areas_on_protect_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_areas_on_protect_class ON public.protected_areas USING btree (protect_class);


--
-- Name: protected_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protected_zones (
    id bigint NOT NULL,
    kat character varying NOT NULL,
    nazev character varying NOT NULL,
    zona character varying NOT NULL,
    objectid integer,
    geometry public.geography,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: protected_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protected_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protected_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_zones ALTER COLUMN id SET DEFAULT nextval('public.protected_zones_id_seq'::regclass);


--
-- Name: protected_zones protected_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_zones
    ADD CONSTRAINT protected_zones_pkey PRIMARY KEY (id);


--
-- Name: index_protected_zones_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_zones_on_geometry ON public.protected_zones USING gist (geometry);


--
-- Name: index_protected_zones_on_kat_and_nazev; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_zones_on_kat_and_nazev ON public.protected_zones USING btree (kat, nazev);


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

--
-- Name: fire_spots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fire_spots (
    id bigint NOT NULL,
    osm_id character varying,
    name character varying,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    geometry public.geography,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: fire_spots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fire_spots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fire_spots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fire_spots ALTER COLUMN id SET DEFAULT nextval('public.fire_spots_id_seq'::regclass);


--
-- Name: fire_spots fire_spots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fire_spots
    ADD CONSTRAINT fire_spots_pkey PRIMARY KEY (id);


--
-- Name: index_fire_spots_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fire_spots_on_geometry ON public.fire_spots USING gist (geometry);


--
-- Name: index_fire_spots_on_osm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fire_spots_on_osm_id ON public.fire_spots USING btree (osm_id);


INSERT INTO public.schema_migrations (version) VALUES
('20250112000000'),
('20260112224855'),
('20260112231425'),
('20260112232120'),
('20260112234316'),
('20260225000000'),
('20260225000001');


--
-- PostgreSQL database dump complete
--


--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: entries; Type: TABLE; Schema: public; Owner: cmps112; Tablespace: 
--

CREATE TABLE entries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    starter_id integer NOT NULL,
    entry text NOT NULL,
    date date DEFAULT now()
);


ALTER TABLE public.entries OWNER TO cmps112;

--
-- Name: entries_id_seq; Type: SEQUENCE; Schema: public; Owner: cmps112
--

CREATE SEQUENCE entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entries_id_seq OWNER TO cmps112;

--
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cmps112
--

ALTER SEQUENCE entries_id_seq OWNED BY entries.id;


--
-- Name: starters; Type: TABLE; Schema: public; Owner: cmps112; Tablespace: 
--

CREATE TABLE starters (
    id integer NOT NULL,
    starter text NOT NULL
);


ALTER TABLE public.starters OWNER TO cmps112;

--
-- Name: starters_id_seq; Type: SEQUENCE; Schema: public; Owner: cmps112
--

CREATE SEQUENCE starters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.starters_id_seq OWNER TO cmps112;

--
-- Name: starters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cmps112
--

ALTER SEQUENCE starters_id_seq OWNED BY starters.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: cmps112; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    ip_address character varying(45)
);


ALTER TABLE public.users OWNER TO cmps112;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: cmps112
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO cmps112;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cmps112
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: cmps112
--

ALTER TABLE ONLY entries ALTER COLUMN id SET DEFAULT nextval('entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: cmps112
--

ALTER TABLE ONLY starters ALTER COLUMN id SET DEFAULT nextval('starters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: cmps112
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Data for Name: entries; Type: TABLE DATA; Schema: public; Owner: cmps112
--

INSERT INTO entries VALUES (399, 33, 7, 'Spring Break', '2014-03-11');
INSERT INTO entries VALUES (401, 34, 4, 'a good day at work yesterday and for the time going by quickly', '2014-03-11');
INSERT INTO entries VALUES (403, 35, 6, 'I walked outside, and the bus came right away - perfect timing! So I had some extra time before class started.', '2014-03-11');
INSERT INTO entries VALUES (411, 35, 7, 'today', '2014-03-11');
INSERT INTO entries VALUES (413, 1, 4, 'taking CMPS 112.', '2014-03-11');
INSERT INTO entries VALUES (415, 1, 4, 'taking CMPS 112.', '2014-03-11');
INSERT INTO entries VALUES (417, 1, 4, 'taking CMPS 112.', '2014-03-11');
INSERT INTO entries VALUES (419, 1, 4, 'taking CMPS 112.', '2014-03-11');
INSERT INTO entries VALUES (427, 5, 6, 'heard a good song', '2014-03-12');
INSERT INTO entries VALUES (429, 5, 6, 'physics lecture', '2014-03-12');
INSERT INTO entries VALUES (437, 1, 2, 'it''s Friday.', '2014-03-14');
INSERT INTO entries VALUES (439, 1, 2, 'it''s a sunny day.', '2014-03-14');
INSERT INTO entries VALUES (441, 43, 2, 'it''s the LAST SAT.', '2014-03-15');
INSERT INTO entries VALUES (445, 39, 2, 'I was alone.', '2014-03-15');
INSERT INTO entries VALUES (447, 38, 2, 'I wasn''t in control tonight.', '2014-03-15');
INSERT INTO entries VALUES (449, 29, 2, 'I got the cookie part done.', '2014-03-15');
INSERT INTO entries VALUES (451, 38, 3, 'the stuff I have learned in such a short period.', '2014-03-15');
INSERT INTO entries VALUES (454, 47, 4, 'finishing this project.', '2014-03-15');
INSERT INTO entries VALUES (456, 47, 5, 'I want to say I hated this damned quarter!', '2014-03-15');
INSERT INTO entries VALUES (458, 5, 5, 'me too!!! to the person below me.', '2014-03-15');
INSERT INTO entries VALUES (469, 35, 4, 'cookies work in Nodejs now', '2014-03-15');
INSERT INTO entries VALUES (471, 38, 2, 'finishing.', '2014-03-15');
INSERT INTO entries VALUES (478, 38, 2, 'today was stressful.', '2014-03-16');
INSERT INTO entries VALUES (480, 39, 7, 'finals week.', '2014-03-16');
INSERT INTO entries VALUES (484, 40, 7, 'finishing this damned project. AHAHAHAHAHA!!!!', '2014-03-16');
INSERT INTO entries VALUES (486, 39, 4, 'CMPS 112         ', '2014-03-17');
INSERT INTO entries VALUES (488, 41, 2, ' science is cool.                               ', '2014-03-17');
INSERT INTO entries VALUES (490, 40, 5, 'I will fail my classes.                                ', '2014-03-17');
INSERT INTO entries VALUES (400, 34, 4, 'dinner with Ashlyn last night and yummy food', '2014-03-11');
INSERT INTO entries VALUES (402, 35, 3, 'sunshine, warmth, time to relax, seeing family and friends today', '2014-03-11');
INSERT INTO entries VALUES (410, 5, 6, 'right now, i think recaptcha is working', '2014-03-11');
INSERT INTO entries VALUES (418, 1, 4, 'taking CMPS 112.', '2014-03-11');
INSERT INTO entries VALUES (428, 5, 3, 'the sun!', '2014-03-12');
INSERT INTO entries VALUES (430, 5, 4, 'cookies', '2014-03-12');
INSERT INTO entries VALUES (438, 1, 2, '....NOT...it''s DEAD WEEK...', '2014-03-14');
INSERT INTO entries VALUES (440, 5, 2, 'its Sat.', '2014-03-15');
INSERT INTO entries VALUES (442, 48, 2, 'it''s FINALS WEEK.', '2014-03-15');
INSERT INTO entries VALUES (444, 8, 2, 'I''m almost done.', '2014-03-15');
INSERT INTO entries VALUES (446, 7, 2, 'I was in control tonight.', '2014-03-15');
INSERT INTO entries VALUES (448, 38, 5, 'I have to finish finals week.', '2014-03-15');
INSERT INTO entries VALUES (450, 38, 2, 'I got the cookie part done.', '2014-03-15');
INSERT INTO entries VALUES (455, 5, 7, 'going to the beach', '2014-03-15');
INSERT INTO entries VALUES (457, 45, 5, 'I want to say I hated this damned quarter!', '2014-03-15');
INSERT INTO entries VALUES (470, 7, 2, 'got it to work.', '2014-03-15');
INSERT INTO entries VALUES (477, 38, 7, 'finals.', '2014-03-16');
INSERT INTO entries VALUES (479, 38, 3, 'for dying from this cough.', '2014-03-16');
INSERT INTO entries VALUES (485, 39, 5, 'I must finish my FINALS...or be finished.', '2014-03-17');
INSERT INTO entries VALUES (487, 40, 4, 'having awesome friends.                       ', '2014-03-17');
INSERT INTO entries VALUES (489, 39, 5, 'I will pass my classes.                    ', '2014-03-17');


--
-- Name: entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cmps112
--

SELECT pg_catalog.setval('entries_id_seq', 498, true);


--
-- Data for Name: starters; Type: TABLE DATA; Schema: public; Owner: cmps112
--

INSERT INTO starters VALUES (7, 'I am looking forward to ');
INSERT INTO starters VALUES (125, 'I am fortunate because ');
INSERT INTO starters VALUES (3, 'I appreciate ');
INSERT INTO starters VALUES (4, 'I am grateful for ');
INSERT INTO starters VALUES (5, 'Before I die, ');
INSERT INTO starters VALUES (6, 'My most memorable moment today was when ');
INSERT INTO starters VALUES (2, 'Today was fun because ');
INSERT INTO starters VALUES (126, 'I am thankful for ');


--
-- Name: starters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cmps112
--

SELECT pg_catalog.setval('starters_id_seq', 126, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: cmps112
--

INSERT INTO users VALUES (1, '200.84.35.79');
INSERT INTO users VALUES (2, '221.7.11.23');
INSERT INTO users VALUES (3, '66.35.68.145');
INSERT INTO users VALUES (4, '27.44.77.171');
INSERT INTO users VALUES (5, '202.116.1.149');
INSERT INTO users VALUES (6, '169.233.229.1');
INSERT INTO users VALUES (7, '169.233.229.1');
INSERT INTO users VALUES (8, '67.169.145.247');
INSERT INTO users VALUES (9, '67.169.145.247');
INSERT INTO users VALUES (10, '67.169.145.247');
INSERT INTO users VALUES (11, '67.169.145.247');
INSERT INTO users VALUES (12, '67.169.145.247');
INSERT INTO users VALUES (13, '127.0.0.1');
INSERT INTO users VALUES (14, '127.0.0.1');
INSERT INTO users VALUES (15, '127.0.0.1');
INSERT INTO users VALUES (16, '127.0.0.1');
INSERT INTO users VALUES (17, '127.0.0.1');
INSERT INTO users VALUES (18, '127.0.0.1');
INSERT INTO users VALUES (19, '127.0.0.1');
INSERT INTO users VALUES (20, '127.0.0.1');
INSERT INTO users VALUES (21, '127.0.0.1');
INSERT INTO users VALUES (22, '127.0.0.1');
INSERT INTO users VALUES (23, '127.0.0.1');
INSERT INTO users VALUES (24, '127.0.0.1');
INSERT INTO users VALUES (25, '127.0.0.1');
INSERT INTO users VALUES (26, '127.0.0.1');
INSERT INTO users VALUES (27, '127.0.0.1');
INSERT INTO users VALUES (28, '127.0.0.1');
INSERT INTO users VALUES (29, '169.233.243.99');
INSERT INTO users VALUES (30, '128.114.107.25');
INSERT INTO users VALUES (31, '127.0.0.1');
INSERT INTO users VALUES (32, '128.114.107.24');
INSERT INTO users VALUES (33, '67.161.60.58');
INSERT INTO users VALUES (34, '67.161.60.58');
INSERT INTO users VALUES (35, '67.161.60.58');
INSERT INTO users VALUES (36, '127.0.0.1');
INSERT INTO users VALUES (37, '67.169.145.247');
INSERT INTO users VALUES (38, '128.114.107.26');
INSERT INTO users VALUES (39, '169.233.255.29');
INSERT INTO users VALUES (40, '128.114.107.7');
INSERT INTO users VALUES (41, '24.5.211.159');
INSERT INTO users VALUES (42, '127.0.0.1');
INSERT INTO users VALUES (43, '128.114.107.15');
INSERT INTO users VALUES (44, '128.114.107.15');
INSERT INTO users VALUES (45, '128.114.107.15');
INSERT INTO users VALUES (46, '128.114.107.15');
INSERT INTO users VALUES (47, '128.114.107.15');
INSERT INTO users VALUES (48, '128.114.107.15');
INSERT INTO users VALUES (49, '128.114.107.15');
INSERT INTO users VALUES (50, '128.114.107.15');
INSERT INTO users VALUES (51, '128.114.107.15');
INSERT INTO users VALUES (52, '128.114.107.15');
INSERT INTO users VALUES (53, '128.114.107.15');
INSERT INTO users VALUES (54, '128.114.107.15');
INSERT INTO users VALUES (55, '128.114.107.15');
INSERT INTO users VALUES (56, '169.233.236.145');


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cmps112
--

SELECT pg_catalog.setval('users_id_seq', 56, true);


--
-- Name: entries_pkey; Type: CONSTRAINT; Schema: public; Owner: cmps112; Tablespace: 
--

ALTER TABLE ONLY entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- Name: starters_pkey; Type: CONSTRAINT; Schema: public; Owner: cmps112; Tablespace: 
--

ALTER TABLE ONLY starters
    ADD CONSTRAINT starters_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: cmps112; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--


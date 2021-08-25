create table THREAD_CONTROL
(
  job_thread_id    INTEGER,
  job_package      VARCHAR2(30),
  job_proc         VARCHAR2(30),
  job_schema       VARCHAR2(30),
  job_thread_count INTEGER,
  is_active        CHAR(1),
  job_notes        VARCHAR2(4000),
  create_date      DATE,
  create_user      VARCHAR2(30),
  update_date      DATE,
  update_user      VARCHAR2(30)
)
tablespace USERS2
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 80K
    next 1M
    minextents 1
    maxextents unlimited
  );

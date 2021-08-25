create table LOAD_A_THREAD
(
  job_id   NUMBER,
  seq      NUMBER,
  message  VARCHAR2(100),
  chunk    NUMBER,
  run_date DATE
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

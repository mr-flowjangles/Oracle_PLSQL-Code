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
;


insert into THREAD_CONTROL (job_thread_id, job_package, job_proc, job_schema, job_thread_count, is_active, job_notes, create_date, create_user, update_date, update_user)
values (5, 'heavyThreader', 'main', user, 5, 'Y', 'Testing the first PX Threading', trunc(sysdate), user, trunc(sysdate), 'dd-mm-yyyy'), user);
commit;

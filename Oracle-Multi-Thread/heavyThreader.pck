create or replace package heavyThreader is

  -- Author  : R.Rose
  -- Created : 2/26/2021 12:36:10 PM
  
 
  -- Public function and procedure declarations
  procedure main(p_chunk  in number,
                 p_job_id in number);

end heavyThreader;
/
create or replace package body heavyThreader is

  --------------------------------------------------------------------------------
  -- Private Constant Declarations
  --------------------------------------------------------------------------------
  G_PACKAGE_NAME CONSTANT VARCHAR2(30) := 'heavyThreader';
  G_SCHEMA_NAME  CONSTANT VARCHAR2(30) := user;
  
    --------------------------------------------------------------------------------
  -- Private Variable Declarations
  --------------------------------------------------------------------------------
  G_RETURN_CD       NUMBER;
  G_LOG_ERRORS      VARCHAR2(1) := 'N';
  G_START_TIMESTAMP TIMESTAMP := TO_TIMESTAMP(SYSDATE);
  G_JOB_ID          integer;

  
  
  --|-------------------------------------------------------------
  --|-- used to declutter code with logging;
  --|-------------------------------------------------------------
  PROCEDURE LOG(P_MSG VARCHAR2, P_OBJ VARCHAR2) IS

    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'log';

    
  BEGIN
    dbms_output.put_line('');
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      G_LOG_ERRORS := 'Y';
      RAISE;
  END LOG;
  -- Private variable declarations
  --<VariableName> <Datatype>;

  procedure LetsThread(p_chunk in number,
                       p_job_id in number)
          
     is
      L_OBJECT_COMPONENT_NAME varchar2(30):= 'Letsthread';  
      l_loopval number;
    begin
    --LOG('chunk '|| p_chunk || ' start', L_OBJECT_COMPONENT_NAME);
    
    select trunc(dbms_random.value(100000,1000000)) into l_loopval from dual;
    
      for i in 1..l_loopval
        loop
       
        insert into load_a_thread
          (job_id, seq, message, chunk, run_date)
        values
          (p_job_id, i, 'message from ' || i, p_chunk, trunc(sysdate));
          commit;
      end loop;  
    
    
    exception
      when others then 
        rule_logger.write_error_log(p_proc_name => L_OBJECT_COMPONENT_NAME,
                                    p_error_cd => sqlcode,
                                    p_error_msg => sqlerrm);
        commit;
    
    end;

-----------------------
  -------------------------------------------------------------------------
  -- main scheduling procedure, will load data for open quarters only.
  -------------------------------------------------------------------------
  procedure main(p_chunk  in number,
                 p_job_id in number) is
    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'main';

  BEGIN
    g_job_id := p_job_id;
    LOG('Package Start chunk: ' ||p_chunk  , L_OBJECT_COMPONENT_NAME);
    -------------------------------------------------
    letsthread(p_chunk, p_job_id);
    commit;
    -------------------------------------------------    
    LOG('Package Complete chunk: ' ||p_chunk , L_OBJECT_COMPONENT_NAME);

EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;

END main;


end heavyThreader;
/

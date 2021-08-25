CREATE OR REPLACE PACKAGE ehr_threading_pkg IS
  
/*  PROCEDURE THREADS(P_CHUNK_ID NUMBER,
                    P_JOB_ID   NUMBER);*/
  
  PROCEDURE main(p_proccess_id in integer);      
END ehr_threading_pkg;
/
CREATE OR REPLACE PACKAGE BODY ehr_threading_pkg IS

  --------------------------------------------------------------------------------
  -- Private Constant Declarations
  --------------------------------------------------------------------------------
  G_PACKAGE_NAME CONSTANT VARCHAR2(30) := 'ehr_threading_pkg';


  --------------------------------------------------------------------------------
  -- Private Variable Declarations
  --------------------------------------------------------------------------------
  --G_RETURN_CD       NUMBER;
  G_LOG_ERRORS      VARCHAR2(1) := 'N';
  G_START_TIMESTAMP TIMESTAMP := TO_TIMESTAMP(SYSDATE);
  G_PROCESS_ID      integer;
  G_JOB_ID          integer;


  --|-------------------------------------------------------------
  --|-- used to declutter code with logging;
  --|-------------------------------------------------------------
  PROCEDURE LOG(P_MSG VARCHAR2, P_OBJ VARCHAR2) IS

    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'log';

    
  BEGIN
    rrose.rule_logger.write_app_log(p_app_name => g_package_name,
                                    p_proc_name => p_obj,
                                    p_message => p_msg,
                                    p_job_id => G_JOB_ID);  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      G_LOG_ERRORS := 'Y';
      rule_logger.write_error_log(p_proc_name => L_OBJECT_COMPONENT_NAME,
                                  p_error_cd => sqlcode,
                                  p_error_msg => sqlerrm);
      
      
      
      RAISE;
  END LOG;

  --|-------------------------------------------------------------
  --|-- INIT
  --|-------------------------------------------------------------
 PROCEDURE INIT IS

    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'init';
  BEGIN
    LOG('Start EHR Threding',L_OBJECT_COMPONENT_NAME);
    
    EXECUTE IMMEDIATE ('alter session set nls_date_format = ''mm/dd/yyyy''');

    g_start_timestamp := TO_TIMESTAMP(SYSDATE);


  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line(sqlerrm); 
     
      RAISE;
  END INIT;

  --|-------------------------------------------------------------
  --|-- used to declutter code with logging;
  --|-------------------------------------------------------------
  PROCEDURE multi_thread_coordinator IS

    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'multi_thread_coordinator';
    l_task_name             varchar2(30):= L_OBJECT_COMPONENT_NAME;
    l_thread_block          VARCHAR2(32000);
    l_code_line             VARCHAR2(1000);
    
    l_pll_session_cnt       thread_control.job_thread_count%type;
    l_job_schema            thread_control.job_schema%type;
    l_job_package           thread_control.job_package%type;
    l_job_proc              thread_control.job_proc%type;

    --------------------------------------------------------------
    -- This procedure is used to set up the required code needed
    -- to schedule the jobs
    --------------------------------------------------------------

  BEGIN
    
    -------------------------------------------------------
    -- Grab the PX Thread Count for process that will run
    -------------------------------------------------------    
    select t.job_thread_count,
           t.job_schema,
           t.job_package,
           t.job_proc
      into l_pll_session_cnt,
           l_job_schema,
           l_job_package,
           l_job_proc
      from thread_control t
     where t.job_thread_id = G_PROCESS_ID;
                                  
    FOR i IN 1..l_pll_session_cnt
      LOOP -- This loop manages how many threads will be created
        l_code_line:= l_code_line ||       
            'when '||i||' then '|| l_job_schema || '.' || l_job_package || '.' || l_job_proc || '('
                   ||i|| ',' || g_job_id || ');' || chr(13);
          
    END LOOP;

     -- this block creates the code needed to schedule the thread.
      l_thread_block 
          := '
            declare
                v_dummy integer := :end_id;
            begin
              case :start_id ' || chr(13) ||
                l_code_line ||
              'end case;
            end;
            ';

      dbms_output.put_line(l_thread_block); 

    -- THIS BLOCK IS USED TO DELETE FORM DBA_VIEWS
      BEGIN
          -- if job isn't there, no prob.
          DBMS_PARALLEL_EXECUTE.DROP_TASK (l_task_name);
      EXCEPTION
          WHEN OTHERS THEN NULL;
      END;

    -- CREATE YOUR PARALLEL TASK
    DBMS_PARALLEL_EXECUTE.create_task(task_name => l_task_name);

    -- DEFINE CHUNK SIZE
    DBMS_PARALLEL_EXECUTE.create_chunks_by_sql(
        task_name   => l_task_name,
        sql_stmt    => 'SELECT level start_id, level end_id FROM dual connect by level <=' || l_pll_session_cnt,
        by_rowid    => FALSE
    );

    DBMS_PARALLEL_EXECUTE.run_task(
        task_name        => l_task_name,
        sql_stmt         => l_thread_block,
        language_flag    => DBMS_SQL.native,
        parallel_level   => l_pll_session_cnt
    );

  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line(sqlerrm);
      RAISE;
  END multi_thread_coordinator;
  
  -------------------------------------------------------------------------
  -- main scheduling procedure, will load data for open quarters only.
  -------------------------------------------------------------------------
  PROCEDURE main(p_proccess_id in integer) IS
    L_OBJECT_COMPONENT_NAME CONSTANT VARCHAR2(30) := 'main';

  BEGIN
    -- initial required variables for logging.
    g_job_id := rrose.v_job_seq.nextval;
    G_PROCESS_ID := p_proccess_id;
    ----------------------------------
    
    LOG(G_PACKAGE_NAME || ' Start', L_OBJECT_COMPONENT_NAME);
    -------------------------------------------------
    init; -- Variable Set up
    multi_thread_coordinator; -- this block manages the threading
    -------------------------------------------------    
    LOG(G_PACKAGE_NAME || ' End', L_OBJECT_COMPONENT_NAME);

EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;

END main;
  


END ehr_threading_pkg;
/


use role ACCOUNTADMIN;


CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.CORTEX_ANALYST_SCHEMA }}.cortex_analyst
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');


--PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/fake_analyst_reports/*.pdf @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.analyst_reports auto_compress = false overwrite = true;


ALTER STAGE {{ env.DATAOPS_DATABASE }}.{{ env.CORTEX_ANALYST_SCHEMA}}.cortex_analyst REFRESH;

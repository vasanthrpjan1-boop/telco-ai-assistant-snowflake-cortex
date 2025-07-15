ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for FSI using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
use role {{ env.EVENT_ATTENDEE_ROLE }};


CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.CORTEX_ANALYST_SCHEMA }}.cortex_analyst
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');


PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/analyst/semantic_model.yaml @{{ env.DATAOPS_DATABASE }}.{{ env.CORTEX_ANALYST_SCHEMA }}.cortex_analyst auto_compress = false overwrite = true;


ALTER STAGE {{ env.DATAOPS_DATABASE }}.{{ env.CORTEX_ANALYST_SCHEMA}}.cortex_analyst REFRESH;

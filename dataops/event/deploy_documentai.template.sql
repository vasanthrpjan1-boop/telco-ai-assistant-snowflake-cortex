use role {{ env.EVENT_ATTENDEE_ROLE }};

create schema IF NOT EXISTS {{env.DATAOPS_DATABASE }}.{{env.DOCUMENT_AI_SCHEMA}}; 
GRANT DATABASE ROLE SNOWFLAKE.DOCUMENT_INTELLIGENCE_CREATOR TO ROLE {{env.EVENT_ATTENDEE_ROLE}};
GRANT CREATE snowflake.ml.document_intelligence on schema {{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }} to role {{env.EVENT_ATTENDEE_ROLE}};
GRANT CREATE MODEL ON SCHEMA {{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }} TO ROLE {{env.EVENT_ATTENDEE_ROLE}};
use role {{ env.EVENT_ATTENDEE_ROLE }};


use role {{ env.EVENT_ATTENDEE_ROLE }};
CREATE STAGE {{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.analyst_reports
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');

CREATE STAGE {{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.infographics
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');

PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/fake_analyst_reports/*.pdf @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.analyst_reports auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/snowflake_infographics/*.pdf @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.infographics auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/snowflake_infographics/*.png @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI_SCHEMA }}.infographics auto_compress = false overwrite = true;
use role {{ env.EVENT_ATTENDEE_ROLE }};

CREATE STAGE {{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI }}.analyst_reports
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');

PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/fake_analyst_reports/*.pdf @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI }}.analyst_reports auto_compress = false overwrite = true;

CREATE STAGE RESEARCH_ANALYSTS_REPORTS.{{ env.DOCUMENT_AI }}.infographics
  DIRECTORY = (enable = true)
  ENCRYPTION = (type = 'snowflake_sse');


PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/snowflake_infographics/*.pdf @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI }}.infographics auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/document_ai/snowflake_infographics/*.png @{{ env.DATAOPS_DATABASE }}.{{ env.DOCUMENT_AI }}.infographics auto_compress = false overwrite = true;
ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
use role {{ env.EVENT_ATTENDEE_ROLE }};

create or replace schema {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }};
-- Create stages for Telco notebooks
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_ANALYSIS DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_INSIGHTS DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_INCIDENT_ANALYSIS DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

------put Telco notebook files in stages

-- Telco Network Analysis Notebook
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/telco_network_analysis/network_performance_analysis.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_ANALYSIS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/telco_network_analysis/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_ANALYSIS auto_compress = false overwrite = true;

-- Telco Customer Insights Notebook
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/telco_customer_insights/customer_analytics.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_INSIGHTS auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/telco_customer_insights/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_INSIGHTS auto_compress = false overwrite = true;



--create Telco notebooks
CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_PERFORMANCE_ANALYSIS
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_ANALYSIS'
MAIN_FILE = 'network_performance_analysis.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"notebook", "type":"network_analysis"}}''';
ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_NETWORK_PERFORMANCE_ANALYSIS ADD LIVE VERSION FROM LAST;

CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_INSIGHTS'
MAIN_FILE = 'customer_analytics.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for Telecommunications using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"notebook", "type":"customer_analytics"}}''';
ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.TELCO_CUSTOMER_ANALYTICS ADD LIVE VERSION FROM LAST;



use role {{ env.EVENT_ATTENDEE_ROLE }};

create schema if not exists {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }};
create stage if not exists {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK_STAGE;

PUT file:///{{ env.CI_PROJECT_DIR}}/solution/notebooks/example_notebook.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK_STAGE auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR}}/solution/notebooks/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK_STAGE auto_compress = false overwrite = true;

CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK
    FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK_STAGE'
    MAIN_FILE = 'example_notebook.ipynb'
    QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.EXAMPLE_NOTEBOOK ADD LIVE VERSION FROM LAST;

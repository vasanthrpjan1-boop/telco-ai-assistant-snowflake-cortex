ALTER SESSION SET QUERY_TAG = '''{"origin":"sf_sit-is", "name":"Build an AI Assistant for FSI using Cortex and Document AI", "version":{"major":1, "minor":0},"attributes":{"is_quickstart":0, "source":"sql"}}''';
ALTER SHARE IF EXISTS {{ env.EVENT_SHARE }} ADD ACCOUNTS={{ env.EVENT_ORG_NAME | lower }}.{{ env.EVENT_CHILD_ACCOUNT_NAME | lower }}

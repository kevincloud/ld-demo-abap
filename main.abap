REPORT sample_test.

CLASS lcl_test DEFINITION.
    PUBLIC SECTION.
        METHODS: 
            constructor,
            run.

    PRIVATE SECTION.
        TYPES:
            BEGIN OF flag_item,
                key TYPE string,
                _value TYPE string,
            END OF flag_item,

            BEGIN OF ld_flags,
                items TYPE STANDARD TABLE OF flag_item,
            END OF ld_flags.

        DATA:
            ld_project_key TYPE string,
            ld_env_key TYPE string,
            ld_api_key TYPE string,
            ld_data TYPE ld_flags,
            ld_http_client TYPE REF TO if_http_client.
ENDCLASS.

CLASS lcl_test IMPLEMENTATION.
    METHOD constructor.
        SELECT SINGLE ld_value FROM ld_config INTO ld_project_key where ld_key = 'LD_API_KEY'.
        SELECT SINGLE ld_value FROM ld_config INTO ld_env_key where ld_key = 'LD_ENV_KEY'.
        SELECT SINGLE ld_value FROM ld_config INTO ld_api_key where ld_key = 'LD_PROJECT_NAME'.
    ENDMETHOD.

    METHOD run.
        DATA:
            url TYPE string value = 'https://app.launchdarkly.com/api/v2/projects/' && project_key && '/environments/' && env_key && '/flags/evaluate',
            context TYPE string value = '{"kind": "device", "key": "dvc-07deac57-fb7a-4b37-8d2a-665533e19e0c"}',
            ld_http_request TYPE REF TO if_http_entity,
            ld_response TYPE string,
            errortext TYPE string.
        
        CALL METHOD cl_http_client=>create_by_url(
            EXPORTING
                url = url
                scheme = 'https'
            IMPORTING
                client = ld_http_client
            EXCEPTIONS
                argument_not_found = 1
                plugin_not_active = 2
                internal_error = 3
                OTHERS = 4).
        
        CALL METHOD ld_http_client->request->set_header_field(
            EXPORTING
                name = 'Authorization'
                value = ld_api_key).

        ld_http_client->request->set_content_type( 'application/json' ).

        CALL METHOD ld_http_client->request->set_method(if_http_client=>co_request_method_post).

        ld_http_request = ld_http_client->request.

        ld_http_request->append_cdata( data = context ).

        CALL METHOD ld_http_client->send(
            EXCEPTIONS
                http_communication_failure = 1
                http_invalid_state         = 2
                http_processing_failed     = 3
                OTHERS                     = 4).

        CALL METHOD ld_http_client->receive(
            EXCEPTIONS
                http_communication_failure = 1
                http_invalid_state         = 2
                http_processing_failed     = 3
                OTHERS                     = 4).
    
        lv_response = lo_http_client->response->get_cdata( ).
        /ui2/cl_json=>deserialize(
            EXPORTING
                json = lv_response
            CHANGING
                data = ld_data
        
        LOOP AT ld_data ASIGNING FIELD-SYMBOL(<fs_data>).
            IF <fs_data>-key = 'release-ai-assistant'.
                IF <fs_data>-_value = 'true'.
                    WRITE 'This is the new code.'.
                ELSE.
                    WRITE 'This is the original code.'.
                ENDIF.
                EXIT.
            ENDIF.
        ENDLOOP.
    ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
    DATA(lo_test) = NEW lcl_test( ).
    lo_test->run( ).


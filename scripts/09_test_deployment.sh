#!/bin/bash

# post-deployment tests


# load local settings if not already loaded
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


# Testing alpha
API_STAGE="alpha"
echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
if [[ $API_HTTP_METHOD == "GET" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}?request_id=${REQUEST_ID}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -X ${API_HTTP_METHOD} \
        ${HTTPS})
fi
if [[ $API_HTTP_METHOD == "POST" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -H  "Content-Type: application/json" \
        -X ${API_HTTP_METHOD} \
        -d '{"request_id": '${REQUEST_ID}'}' \
        ${HTTPS})
fi
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
    "call: $(FC $(echo "$CURL_OUT" | md5sum))"

if [[ $API_ALIAS_RESOURCE_USE != "false" ]]; then
    echo
    echo -e "$INFO Testing $(FC ${API_STAGE}/${API_ALIAS_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
    if [[ $API_HTTP_METHOD == "GET" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}?request_id=${REQUEST_ID}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -X ${API_HTTP_METHOD} \
            ${HTTPS})
    fi
    if [[ $API_HTTP_METHOD == "POST" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -H  "Content-Type: application/json" \
            -X ${API_HTTP_METHOD} \
            -d '{"request_id": '${REQUEST_ID}'}' \
            ${HTTPS})
    fi
    [[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
    echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
        "call: $(FC $(echo "$CURL_OUT" | md5sum))"
fi

# Testing beta
API_STAGE="beta"
echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
if [[ $API_HTTP_METHOD == "GET" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}?request_id=${REQUEST_ID}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -X ${API_HTTP_METHOD} \
        ${HTTPS})
fi
if [[ $API_HTTP_METHOD == "POST" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -H  "Content-Type: application/json" \
        -X ${API_HTTP_METHOD} \
        -d '{"request_id": '${REQUEST_ID}'}' \
        ${HTTPS})
fi
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
    "call: $(FC $(echo "$CURL_OUT" | md5sum))"

if [[ $API_ALIAS_RESOURCE_USE != "false" ]]; then
    echo
    echo -e "$INFO Testing $(FC ${API_STAGE}/${API_ALIAS_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
    if [[ $API_HTTP_METHOD == "GET" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}?request_id=${REQUEST_ID}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -X ${API_HTTP_METHOD} \
            ${HTTPS})
    fi
    if [[ $API_HTTP_METHOD == "POST" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -H  "Content-Type: application/json" \
            -X ${API_HTTP_METHOD} \
            -d '{"request_id": '${REQUEST_ID}'}' \
            ${HTTPS})
    fi
    [[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
    echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
        "call: $(FC $(echo "$CURL_OUT" | md5sum))"
fi

# Testing prod
API_STAGE="prod"
echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
if [[ $API_HTTP_METHOD == "GET" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}?request_id=${REQUEST_ID}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -X ${API_HTTP_METHOD} \
        ${HTTPS})
fi
if [[ $API_HTTP_METHOD == "POST" ]]; then
    HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_RESOURCE_NAME}"
    echo -e "$INFO $(FY ${HTTPS})"
    CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
        -H  "Content-Type: application/json" \
        -X ${API_HTTP_METHOD} \
        -d '{"request_id": '${REQUEST_ID}'}' \
        ${HTTPS})
fi
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
    "call: $(FC $(echo "$CURL_OUT" | md5sum))"

if [[ $API_ALIAS_RESOURCE_USE != "false" ]]; then
    echo
    echo -e "$INFO Testing $(FC ${API_STAGE}/${API_ALIAS_RESOURCE_NAME}) $(FY ${API_HTTP_METHOD}) call."
    if [[ $API_HTTP_METHOD == "GET" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}?request_id=${REQUEST_ID}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -X ${API_HTTP_METHOD} \
            ${HTTPS})
    fi
    if [[ $API_HTTP_METHOD == "POST" ]]; then
        HTTPS="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME}"
        echo -e "$INFO $(FY ${HTTPS})"
        CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
            -H  "Content-Type: application/json" \
            -X ${API_HTTP_METHOD} \
            -d '{"request_id": '${REQUEST_ID}'}' \
            ${HTTPS})
    fi
    [[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
    echo -e "$INFO Result (md5) of $(FC ${API_STAGE}/${API_RESOURCE_NAME})" \
        "call: $(FC $(echo "$CURL_OUT" | md5sum))"
fi

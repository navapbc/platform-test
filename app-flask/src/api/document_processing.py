import logging
import os
import uuid
from typing import Any, Dict, Tuple

import boto3
from apiflask import APIBlueprint
from marshmallow import fields
from werkzeug.exceptions import BadRequest, InternalServerError

from src.api import response
from src.api.schemas import request_schema

logger = logging.getLogger(__name__)


class DocumentProcessingRequestSchema(request_schema.OrderedSchema):
    trace_id = fields.Str(
        required=False, metadata={"description": "Optional trace ID for tracking"}
    )
    file_key = fields.Str(required=True, metadata={"description": "S3 key of the file to process"})


class DocumentProcessingResponseSchema(request_schema.OrderedSchema):
    dde_response = fields.Dict(metadata={"description": "DDE processing results"})
    job_id = fields.Str(metadata={"description": "Job ID assigned to the processing task"})


document_processing_blueprint = APIBlueprint(
    "document_processing", __name__, tag="Document Processing"
)


@document_processing_blueprint.post("/test-document-data-extraction-config")
@document_processing_blueprint.input(DocumentProcessingRequestSchema)
@document_processing_blueprint.output(DocumentProcessingResponseSchema)
@document_processing_blueprint.doc(responses=[200, BadRequest.code, InternalServerError.code])
def test_document_data_extraction_processing(
    json_data: Dict[str, Any]
) -> Tuple[response.ApiResponse, int]:
    """Test document data extraction processing with a file from the input bucket."""

    file_key = json_data["file_key"]
    trace_id = json_data.get("trace_id") or str(uuid.uuid4())
    input_bucket = os.getenv("DDE_INPUT_LOCATION")
    output_bucket = os.getenv("DDE_OUTPUT_LOCATION")
    project_arn = os.getenv("DDE_PROJECT_ARN")
    profile_arn = os.getenv("DDE_PROFILE_ARN")
    job_id = str(uuid.uuid4())

    if not input_bucket or not project_arn:
        logger.error(
            f"Missing DDE configuration: input_bucket={input_bucket}, project_arn={project_arn}"
        )
        return (
            response.ApiResponse(
                message="DDE configuration not available",
                errors=[
                    response.ValidationErrorDetail(
                        type="configuration", message="Missing DDE environment variables"
                    )
                ],
            ),
            BadRequest.code,
        )

    try:
        bedrock = boto3.client("bedrock-data-automation-runtime")

        logger.info(f"Invoking DDE for file:  s3://{input_bucket}/{file_key}; trace_id: {trace_id}")
        bedrock_response = bedrock.invoke_data_automation_async(
            dataAutomationProfileArn=profile_arn,
            dataAutomationConfiguration={"dataAutomationProjectArn": project_arn},
            inputConfiguration={"s3Uri": f"{input_bucket}/{file_key}"},
            outputConfiguration={"s3Uri": f"{output_bucket}/{file_key}"},
        )
        logger.info(
            f"DDE invocation successful for file: {file_key}, invocation_arn: {bedrock_response.get('invocationArn')}"
        )

        return (
            response.ApiResponse(
                message="DDE processing initiated successfully",
                data={
                    "dde_response": bedrock_response,
                    "job_id": job_id,
                },
            ),
            200,
        )

    except Exception as e:
        logger.exception(f"Failed to process document with DDE: {str(e)}")
        return (
            response.ApiResponse(
                message="DDE processing failed",
                errors=[response.ValidationErrorDetail(type="processing", message=str(e))],
            ),
            InternalServerError.code,
        )

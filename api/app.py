
from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import os
import time
import pyodbc


app = Flask(__name__)
CORS(app)


def get_active_fault():
    """Read the fault injected through App Service settings."""

    operation = os.environ.get("IGAI_FAULT_OPERATION", "").strip()

    if not operation:
        return None

    try:
        parameters = json.loads(
            os.environ.get("IGAI_FAULT_PARAMETERS", "{}")
        )
    except json.JSONDecodeError:
        app.logger.error("Invalid IGAI_FAULT_PARAMETERS setting")
        return None

    return {
        "operation": operation,
        "parameters": parameters,
    }


# Startup failure is deliberately checked during application startup.
_startup_fault = get_active_fault()

if (
    _startup_fault
    and _startup_fault["operation"] == "simulate_startup_failure"
):
    raise RuntimeError("IGAI injected an application startup failure.")


@app.before_request
def inject_application_availability_fault():
    fault = get_active_fault()

    if not fault:
        return None

    if fault["operation"] == "simulate_app_unavailable":
        return jsonify({
            "error": "Service temporarily unavailable"
        }), 503

    return None


def get_connection():
    fault = get_active_fault()

    if fault:
        operation = fault["operation"]
        parameters = fault["parameters"]

        if operation == "simulate_dependency_timeout":
            timeout = int(parameters.get("timeout_seconds", 30))
            time.sleep(timeout)

        elif operation == "simulate_database_unavailable":
            raise ConnectionError(
                "IGAI: simulated database unavailability."
            )

        elif operation == "simulate_database_authentication_failure":
            raise RuntimeError(
                "IGAI: simulated SQL authentication failure "
                "(SQL error 18456)."
            )

        elif operation == "simulate_database_connection_exhaustion":
            raise ConnectionError(
                "IGAI: simulated database connection exhaustion."
            )

    server = os.environ["DB_SERVER"]
    database = os.environ["DB_NAME"]

    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Authentication=ActiveDirectoryMsi;"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )

    return pyodbc.connect(connection_string)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "service": "customerapp-api"
    }), 200


@app.route("/customers", methods=["GET"])
def get_customers():
    try:
        with get_connection() as connection:
            cursor = connection.cursor()

            cursor.execute("""
                SELECT id, name, email
                FROM dbo.customers
                ORDER BY id
            """)

            customers = [
                {
                    "id": row.id,
                    "name": row.name,
                    "email": row.email
                }
                for row in cursor.fetchall()
            ]

        return jsonify(customers), 200

    except Exception:
        app.logger.exception("Failed to retrieve customers")
        return jsonify({
            "error": "Unable to retrieve customers"
        }), 500


@app.route("/customers", methods=["POST"])
def create_customer():
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "error": "JSON request body required"
            }), 400

        name = data.get("name")
        email = data.get("email")

        if not name or not email:
            return jsonify({
                "error": "Name and email are required"
            }), 400

        with get_connection() as connection:
            cursor = connection.cursor()

            cursor.execute("""
                INSERT INTO dbo.customers (name, email)
                OUTPUT INSERTED.id
                VALUES (?, ?)
            """, (name, email))

            customer_id = cursor.fetchone()[0]
            connection.commit()

        return jsonify({
            "id": customer_id,
            "name": name,
            "email": email
        }), 201

    except Exception:
        app.logger.exception("Failed to create customer")
        return jsonify({
            "error": "Unable to create customer"
        }), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)

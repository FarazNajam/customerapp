
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import pyodbc

app = Flask(__name__)
CORS(app)


def get_connection():
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

    except Exception as e:
        app.logger.exception("Failed to retrieve customers")
        return jsonify({
            "error": "Unable to retrieve customers",
            "details": str(e)
        }), 500


@app.route("/customers", methods=["POST"])
def create_customer():
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "JSON request body required"}), 400

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

    except Exception as e:
        app.logger.exception("Failed to create customer")
        return jsonify({
            "error": "Unable to create customer",
            "details": str(e)
        }), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)

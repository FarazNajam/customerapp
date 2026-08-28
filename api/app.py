from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import pyodbc

app = Flask(__name__)

# Allow the frontend to call the API
CORS(app)


def get_connection():
    server = os.environ["DB_SERVER"]
    database = os.environ["DB_NAME"]
    username = os.environ["DB_USERNAME"]
    password = os.environ["DB_PASSWORD"]

    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=10;"
    )

    return pyodbc.connect(connection_string)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "application": "customerapp-api"
    })


@app.route("/customers", methods=["GET"])
def get_customers():

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT id, name, email FROM customers ORDER BY id"
        )

        customers = []

        for row in cursor.fetchall():
            customers.append({
                "id": row.id,
                "name": row.name,
                "email": row.email
            })

        cursor.close()
        conn.close()

        return jsonify(customers)

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route("/customers", methods=["POST"])
def create_customer():

    data = request.get_json()

    if not data:
        return jsonify({
            "error": "JSON body required"
        }), 400

    name = data.get("name")
    email = data.get("email")

    if not name or not email:
        return jsonify({
            "error": "name and email are required"
        }), 400

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO customers (name, email)
            VALUES (?, ?)
            """,
            name,
            email
        )

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "message": "Customer created",
            "name": name,
            "email": email
        }), 201

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 8000))
    )
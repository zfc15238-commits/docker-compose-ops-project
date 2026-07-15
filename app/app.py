from flask import Flask, jsonify
import pymysql

app = Flask(__name__)


def get_db_connection():
    return pymysql.connect(
        host="mysql",
        port=3306,
        user="root",
        password="123456",
        database="compose_test",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )


@app.route("/")
def hello():
    return "hello docker app\n"


@app.route("/health")
def health():
    return "app is running\n"


@app.route("/users")
def users():
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM compose_users;")
            result = cursor.fetchall()
        return jsonify(result)
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

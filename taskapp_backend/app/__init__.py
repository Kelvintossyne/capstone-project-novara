from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
from urllib.parse import quote_plus

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)

    # Environment variables
    db_host = os.getenv('DATABASE_HOST', 'postgres')
    db_port = os.getenv('DATABASE_PORT', '5432')
    db_name = os.getenv('DATABASE_NAME', 'taskapp')
    db_user = os.getenv('DATABASE_USER', 'taskapp_user')
    db_password = os.getenv('DATABASE_PASSWORD', 'taskapp_password')

    encoded_password = quote_plus(db_password)

    database_uri = (
        f"postgresql://{db_user}:{encoded_password}@{db_host}:{db_port}/{db_name}"
    )

    print("Connecting to DB at:", db_host)

    app.config['SQLALCHEMY_DATABASE_URI'] = database_uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

    db.init_app(app)
    CORS(app)

    from app.routes import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    return app

"""WSGI entry point for hosting (gunicorn / PythonAnywhere):  gunicorn wsgi:app"""
from app import create_app

app = create_app()

"""Py-08-01: Functions do one thing only (PASS)"""


def validate_email(email: str) -> bool:
    """Validate email format."""
    return "@" in email and "." in email


def send_email(to: str, subject: str, body: str) -> bool:
    """Send an email to the recipient."""
    # Email sending logic
    print(f"Sending to {to}: {subject}")
    return True


def log_email_sent(to: str, subject: str) -> None:
    """Log that an email was sent."""
    print(f"Email sent to {to} with subject: {subject}")


def process_notification(email: str, message: str) -> bool:
    """Process and send a notification email."""
    if not validate_email(email):
        return False

    success = send_email(email, "Notification", message)
    if success:
        log_email_sent(email, "Notification")

    return success

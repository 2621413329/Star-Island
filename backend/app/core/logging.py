import sys
from pathlib import Path
from loguru import logger

def setup_logging() -> None:
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    logger.remove()
    logger.add(sys.stdout, level="INFO", enqueue=True)
    logger.add(log_dir / "app.log", level="INFO", rotation="10 MB", retention="30 days", compression="zip", enqueue=True)
    logger.add(log_dir / "error.log", level="ERROR", rotation="10 MB", retention="60 days", compression="zip", enqueue=True)

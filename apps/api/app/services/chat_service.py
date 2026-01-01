"""
Chat persistence service
Save and load chats from database
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc
import logging

from app.database.models import Chat, Message, Project, User

logger = logging.getLogger(__name__)


class ChatService:
    """Service for chat operations"""
    
    @staticmethod
    def create_chat(
        db: Session,
        user_id: str,
        title: Optional[str] = None,
        project_id: Optional[str] = None,
        model: Optional[str] = None,
        key_mode: str = "free"
    ) -> Chat:
        """Create new chat"""
        chat = Chat(
            project_id=project_id,
            title=title or "New Chat",
            model=model,
            key_mode=key_mode,
        )
        
        db.add(chat)
        db.commit()
        db.refresh(chat)
        
        logger.info(f"Created chat {chat.id} for user {user_id}")
        return chat
    
    @staticmethod
    def get_user_chats(
        db: Session,
        user_id: str,
        limit: int = 50,
        offset: int = 0,
        project_id: Optional[str] = None
    ) -> List[Chat]:
        """Get user's chats"""
        query = db.query(Chat).join(Project).filter(Project.owner_id == user_id)
        
        if project_id:
            query = query.filter(Chat.project_id == project_id)
        
        query = query.filter(Chat.archived_at.is_(None))
        query = query.order_by(desc(Chat.updated_at))
        
        return query.limit(limit).offset(offset).all()
    
    @staticmethod
    def get_chat(db: Session, chat_id: str) -> Optional[Chat]:
        """Get chat by ID"""
        return db.query(Chat).filter(Chat.id == chat_id).first()
    
    @staticmethod
    def update_chat_title(db: Session, chat_id: str, title: str) -> Optional[Chat]:
        """Update chat title"""
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        
        if chat:
            chat.title = title
            db.commit()
            db.refresh(chat)
        
        return chat
    
    @staticmethod
    def pin_chat(db: Session, chat_id: str, pinned: bool = True) -> Optional[Chat]:
        """Pin or unpin chat"""
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        
        if chat:
            chat.pinned = pinned
            db.commit()
            db.refresh(chat)
        
        return chat
    
    @staticmethod
    def archive_chat(db: Session, chat_id: str) -> Optional[Chat]:
        """Archive chat"""
        from datetime import datetime
        
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        
        if chat:
            chat.archived_at = datetime.utcnow()
            db.commit()
            db.refresh(chat)
        
        return chat
    
    @staticmethod
    def delete_chat(db: Session, chat_id: str) -> bool:
        """Delete chat permanently"""
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        
        if chat:
            db.delete(chat)
            db.commit()
            logger.info(f"Deleted chat {chat_id}")
            return True
        
        return False
    
    @staticmethod
    def add_message(
        db: Session,
        chat_id: str,
        role: str,
        content: str,
        tokens_input: int = 0,
        tokens_output: int = 0,
        cost: float = 0.0,
        model_used: Optional[str] = None
    ) -> Message:
        """Add message to chat"""
        message = Message(
            chat_id=chat_id,
            role=role,
            content=content,
            tokens_input=tokens_input,
            tokens_output=tokens_output,
            cost=cost,
            model_used=model_used,
        )
        
        db.add(message)
        
        # Update chat timestamp
        chat = db.query(Chat).filter(Chat.id == chat_id).first()
        if chat:
            from datetime import datetime
            chat.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(message)
        
        return message
    
    @staticmethod
    def get_chat_messages(
        db: Session,
        chat_id: str,
        limit: int = 100
    ) -> List[Message]:
        """Get messages for chat"""
        return db.query(Message).filter(
            Message.chat_id == chat_id
        ).order_by(Message.created_at).limit(limit).all()

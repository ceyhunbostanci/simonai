"""
Audit Service - MVP-1
Structured logging with cost ledger, approval ledger, and evidence storage
"""
import json
import os
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

class AuditService:
    """
    Comprehensive audit system
    - Cost ledger (track all AI API costs)
    - Approval ledger (track all approval decisions)
    - Evidence storage (screenshots, logs)
    """
    
    def __init__(self):
        self.audit_dir = Path(os.getenv('SIMON_AUDIT_PATH', '/tmp/simon-audit'))
        self.cost_ledger_path = self.audit_dir / 'cost_ledger.jsonl'
        self.approval_ledger_path = self.audit_dir / 'approval_ledger.jsonl'
        self.event_log_path = self.audit_dir / 'events.jsonl'
        self._ensure_audit_dir()
    
    def _ensure_audit_dir(self):
        """Create audit directory if not exists"""
        try:
            self.audit_dir.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            print(f"Warning: Cannot create audit dir: {e}")
    
    def _write_jsonl(self, filepath: Path, record: Dict[str, Any]):
        """Write JSON line to file"""
        try:
            with open(filepath, 'a', encoding='utf-8') as f:
                f.write(json.dumps(record, ensure_ascii=False) + '\n')
        except Exception as e:
            print(f"Audit write error: {e}")
    
    def log_event(self, event_type: str, data: Dict[str, Any], metadata: Optional[Dict[str, Any]] = None):
        """Log general event"""
        record = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'event_type': event_type,
            'data': data,
            'metadata': metadata or {}
        }
        self._write_jsonl(self.event_log_path, record)
    
    def log_cost(self, session_id: str, model: str, provider: str, 
                 input_tokens: int, output_tokens: int, 
                 cost_input: float, cost_output: float):
        """Log AI model cost"""
        total_cost = cost_input + cost_output
        record = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'session_id': session_id,
            'model': model,
            'provider': provider,
            'input_tokens': input_tokens,
            'output_tokens': output_tokens,
            'total_tokens': input_tokens + output_tokens,
            'cost_input': round(cost_input, 6),
            'cost_output': round(cost_output, 6),
            'total_cost': round(total_cost, 6)
        }
        self._write_jsonl(self.cost_ledger_path, record)
        return total_cost
    
    def log_approval(self, session_id: str, action_id: str, 
                    risk_level: str, approved: bool, 
                    approver: str, reason: Optional[str] = None):
        """Log approval decision"""
        record = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'session_id': session_id,
            'action_id': action_id,
            'risk_level': risk_level,
            'approved': approved,
            'approver': approver,
            'reason': reason,
            'decision_latency_seconds': None  # Will be calculated if timestamps provided
        }
        self._write_jsonl(self.approval_ledger_path, record)
    
    def get_cost_summary(self, session_id: Optional[str] = None) -> Dict[str, Any]:
        """Get cost summary"""
        try:
            total_cost = 0.0
            total_tokens = 0
            model_breakdown = {}
            
            with open(self.cost_ledger_path, 'r', encoding='utf-8') as f:
                for line in f:
                    record = json.loads(line)
                    if session_id and record.get('session_id') != session_id:
                        continue
                    
                    total_cost += record.get('total_cost', 0)
                    total_tokens += record.get('total_tokens', 0)
                    
                    model = record.get('model', 'unknown')
                    if model not in model_breakdown:
                        model_breakdown[model] = {'cost': 0, 'tokens': 0, 'calls': 0}
                    model_breakdown[model]['cost'] += record.get('total_cost', 0)
                    model_breakdown[model]['tokens'] += record.get('total_tokens', 0)
                    model_breakdown[model]['calls'] += 1
            
            return {
                'total_cost': round(total_cost, 6),
                'total_tokens': total_tokens,
                'model_breakdown': model_breakdown
            }
        except FileNotFoundError:
            return {'total_cost': 0.0, 'total_tokens': 0, 'model_breakdown': {}}
        except Exception as e:
            return {'error': str(e)}

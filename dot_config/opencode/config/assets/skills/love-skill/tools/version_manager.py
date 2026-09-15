#!/usr/bin/env python3
"""
版本管理工具
管理配对分析的版本历史
"""

import sys
import json
import shutil
from pathlib import Path
from datetime import datetime

def create_backup(match_dir):
    """为配对创建备份"""
    match_path = Path(match_dir)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    history_dir = match_path / "history"
    history_dir.mkdir(exist_ok=True)
    
    backup_dir = history_dir / f"backup_{timestamp}"
    
    # 复制所有文件（除了 history 目录本身）
    for item in match_path.iterdir():
        if item.name != "history":
            if item.is_file():
                shutil.copy2(item, backup_dir)
            elif item.is_dir():
                shutil.copytree(item, backup_dir / item.name)
    
    return backup_dir

def list_versions(match_dir):
    """列出配对的所有版本"""
    match_path = Path(match_dir)
    history_dir = match_path / "history"
    
    if not history_dir.exists():
        return []
    
    versions = []
    for backup in sorted(history_dir.iterdir(), reverse=True):
        if backup.is_dir():
            versions.append({
                'version': backup.name,
                'timestamp': backup.stat().st_mtime
            })
    
    return versions

def rollback(match_dir, version):
    """回滚到指定版本"""
    match_path = Path(match_dir)
    backup_dir = match_path / "history" / version
    
    if not backup_dir.exists():
        print(f"错误: 版本不存在 - {version}", file=sys.stderr)
        return False
    
    # 创建当前版本的备份，然后恢复
    current_backup = match_path / "history" / f"backup_rollback_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    current_backup.mkdir(parents=True, exist_ok=True)
    
    # 复制当前文件
    for item in match_path.iterdir():
        if item.name != "history":
            if item.is_file():
                shutil.copy2(item, current_backup)
    
    # 恢复备份
    for item in backup_dir.iterdir():
        dest = match_path / item.name
        if dest.exists():
            if dest.is_dir():
                shutil.rmtree(dest)
            else:
                dest.unlink()
        
        if item.is_dir():
            shutil.copytree(item, dest)
        else:
            shutil.copy2(item, dest)
    
    return True

def main():
    if len(sys.argv) < 2:
        print("用法: python3 version_manager.py [backup|list|rollback] <match_dir> [version]", file=sys.stderr)
        sys.exit(1)
    
    action = sys.argv[1]
    match_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    
    if action == 'backup':
        backup_path = create_backup(match_dir)
        print(json.dumps({
            'status': 'success',
            'backup_dir': str(backup_path)
        }, ensure_ascii=False, indent=2))
    
    elif action == 'list':
        versions = list_versions(match_dir)
        print(json.dumps({
            'versions': versions
        }, ensure_ascii=False, indent=2))
    
    elif action == 'rollback':
        if len(sys.argv) < 4:
            print("错误: 需要指定版本", file=sys.stderr)
            sys.exit(1)
        
        version = sys.argv[3]
        success = rollback(match_dir, version)
        
        print(json.dumps({
            'status': 'success' if success else 'failed',
            'version': version
        }, ensure_ascii=False, indent=2))
    
    else:
        print(f"错误: 未知操作 - {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

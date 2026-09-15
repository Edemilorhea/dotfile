#!/usr/bin/env python3
"""
Skill 文件生成和管理工具
"""

import sys
import json
import os
from pathlib import Path
from datetime import datetime

def create_match_directory(pair_slug):
    """创建配对目录结构"""
    match_dir = Path(f"matches/{pair_slug}")
    match_dir.mkdir(parents=True, exist_ok=True)
    return match_dir

def save_persona(match_dir, person_name, persona_content):
    """保存 Persona 文件"""
    slug = person_name.lower().replace(' ', '_')
    filepath = match_dir / f"persona-{slug}.md"
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(persona_content)
    
    return filepath

def save_compatibility(match_dir, compat_data):
    """保存兼容性分析"""
    filepath = match_dir / "compatibility.json"
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(compat_data, f, ensure_ascii=False, indent=2)
    
    return filepath

def save_report(match_dir, report_content):
    """保存最终报告"""
    filepath = match_dir / "report.md"
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    return filepath

def list_matches():
    """列出所有已生成的配对"""
    matches_dir = Path("matches")
    
    if not matches_dir.exists():
        print("未找到任何配对", file=sys.stderr)
        return []
    
    matches = []
    for match_dir in matches_dir.iterdir():
        if match_dir.is_dir():
            # 检查是否有必要文件
            has_personas = len(list(match_dir.glob("persona-*.md"))) >= 2
            has_report = (match_dir / "report.md").exists()
            
            matches.append({
                'slug': match_dir.name,
                'created': datetime.fromtimestamp(match_dir.stat().st_ctime).isoformat(),
                'has_personas': has_personas,
                'has_report': has_report
            })
    
    return matches

def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    
    if action == 'list' or action == 'list-matches':
        matches = list_matches()
        print(json.dumps(matches, ensure_ascii=False, indent=2))
    
    elif action == 'create':
        if len(sys.argv) < 3:
            print("错误: 需要提供配对 slug", file=sys.stderr)
            sys.exit(1)
        
        pair_slug = sys.argv[2]
        match_dir = create_match_directory(pair_slug)
        print(f"已创建配对目录: {match_dir}")
    
    elif action == 'delete':
        if len(sys.argv) < 3:
            print("错误: 需要提供配对 slug", file=sys.stderr)
            sys.exit(1)
        
        pair_slug = sys.argv[2]
        match_dir = Path(f"matches/{pair_slug}")
        
        if match_dir.exists():
            import shutil
            shutil.rmtree(match_dir)
            print(f"已删除配对: {pair_slug}")
        else:
            print(f"错误: 配对不存在 - {pair_slug}", file=sys.stderr)
    
    else:
        print(f"错误: 未知操作 - {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

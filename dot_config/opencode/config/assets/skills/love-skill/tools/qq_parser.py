#!/usr/bin/env python3
"""
QQ 聊天记录解析工具
支持 QQ 导出的多种格式
"""

import sys
import json
import re
from pathlib import Path

def parse_qq_txt(filepath):
    """解析 QQ TXT 格式聊天记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # QQ 记录通常格式：[时间] 昵称 说: 内容
        pattern = r'\n\[(.+?)\]\s+(.+?)\s+说:\s+(.+?)(?=\n\[|$)'
        matches = re.findall(pattern, content, re.DOTALL)
        
        for match in matches:
            timestamp, nickname, message = match
            messages.append({
                'timestamp': timestamp,
                'sender': nickname,
                'content': message.strip(),
                'type': 'text'
            })
    except Exception as e:
        print(f"错误: 无法解析 QQ TXT 文件 - {e}", file=sys.stderr)
    
    return messages

def parse_qq_json(filepath):
    """解析 QQ JSON 格式聊天记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if isinstance(data, list):
            messages = data
        elif 'messages' in data:
            messages = data['messages']
    except Exception as e:
        print(f"错误: 无法解析 QQ JSON 文件 - {e}", file=sys.stderr)
    
    return messages

def parse_qq_mht(filepath):
    """解析 QQ MHT 格式聊天记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # MHT 是网页存档格式，包含 HTML
        # 提取消息内容
        pattern = r'<div[^>]*?>(\d{4}/\d{1,2}/\d{1,2} \d{1,2}:\d{1,2}:\d{1,2})</div>.*?<div[^>]*?>(.+?)</div>.*?<div[^>]*?>(.+?)</div>'
        
        matches = re.findall(pattern, content, re.DOTALL)
        for timestamp, sender, msg_content in matches:
            messages.append({
                'timestamp': timestamp,
                'sender': sender.strip(),
                'content': msg_content.strip(),
                'type': 'text'
            })
    except Exception as e:
        print(f"错误: 无法解析 QQ MHT 文件 - {e}", file=sys.stderr)
    
    return messages

def main():
    if len(sys.argv) < 2:
        print("用法: python3 qq_parser.py <文件路径>", file=sys.stderr)
        sys.exit(1)
    
    filepath = sys.argv[1]
    file_ext = Path(filepath).suffix.lower()
    
    messages = []
    
    if file_ext == '.txt':
        messages = parse_qq_txt(filepath)
    elif file_ext == '.json':
        messages = parse_qq_json(filepath)
    elif file_ext == '.mht':
        messages = parse_qq_mht(filepath)
    else:
        print(f"错误: 不支持的文件格式 {file_ext}", file=sys.stderr)
        sys.exit(1)
    
    output = {
        'source': 'QQ',
        'total_messages': len(messages),
        'messages': messages
    }
    
    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

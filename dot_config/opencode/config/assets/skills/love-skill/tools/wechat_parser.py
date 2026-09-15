#!/usr/bin/env python3
"""
微信聊天记录解析工具
支持不同格式的微信导出记录
"""

import sys
import json
import re
from pathlib import Path

def parse_txt(filepath):
    """解析 TXT 格式微信记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 基础模式：[时间] 昵称: 内容
        pattern = r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] (.+): (.+)'
        matches = re.findall(pattern, content)
        
        for match in matches:
            timestamp, nickname, message = match
            messages.append({
                'timestamp': timestamp,
                'sender': nickname,
                'content': message,
                'type': 'text'
            })
    except Exception as e:
        print(f"错误: 无法解析 TXT 文件 - {e}", file=sys.stderr)
    
    return messages

def parse_json(filepath):
    """解析 JSON 格式微信记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 假设 JSON 结构为列表
        if isinstance(data, list):
            messages = data
        elif isinstance(data, dict) and 'messages' in data:
            messages = data['messages']
    except Exception as e:
        print(f"错误: 无法解析 JSON 文件 - {e}", file=sys.stderr)
    
    return messages

def parse_html(filepath):
    """解析 HTML 格式微信记录"""
    messages = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 简单的 HTML 正则提取
        # 实际应该用 BeautifulSoup，但为了避免依赖，这里用简单正则
        pattern = r'<div class="message">.*?<span class="time">(.+?)</span>.*?<span class="sender">(.+?)</span>.*?<span class="content">(.+?)</span>'
        
        matches = re.findall(pattern, content, re.DOTALL)
        for match in matches:
            timestamp, sender, content = match
            messages.append({
                'timestamp': timestamp,
                'sender': sender,
                'content': content,
                'type': 'text'
            })
    except Exception as e:
        print(f"错误: 无法解析 HTML 文件 - {e}", file=sys.stderr)
    
    return messages

def parse_csv(filepath):
    """解析 CSV 格式微信记录"""
    messages = []
    try:
        import csv
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                messages.append({
                    'timestamp': row.get('timestamp') or row.get('time'),
                    'sender': row.get('sender') or row.get('nickname'),
                    'content': row.get('content') or row.get('message'),
                    'type': row.get('type', 'text')
                })
    except Exception as e:
        print(f"错误: 无法解析 CSV 文件 - {e}", file=sys.stderr)
    
    return messages

def main():
    if len(sys.argv) < 2:
        print("用法: python3 wechat_parser.py <文件路径>", file=sys.stderr)
        sys.exit(1)
    
    filepath = sys.argv[1]
    file_ext = Path(filepath).suffix.lower()
    
    messages = []
    
    if file_ext == '.txt':
        messages = parse_txt(filepath)
    elif file_ext == '.json':
        messages = parse_json(filepath)
    elif file_ext == '.html':
        messages = parse_html(filepath)
    elif file_ext == '.csv':
        messages = parse_csv(filepath)
    else:
        print(f"错误: 不支持的文件格式 {file_ext}", file=sys.stderr)
        sys.exit(1)
    
    # 输出 JSON
    output = {
        'source': 'WeChat',
        'total_messages': len(messages),
        'messages': messages
    }
    
    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

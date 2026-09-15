#!/usr/bin/env python3
"""
社交媒体内容解析工具
支持朋友圈、微博等内容提取
"""

import sys
import json
import re
from pathlib import Path

def parse_social_text(filepath):
    """解析纯文本社交内容"""
    posts = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 按段落分割
        paragraphs = content.split('\n\n')
        
        for para in paragraphs:
            if para.strip():
                posts.append({
                    'content': para.strip(),
                    'type': 'text',
                    'metadata': {}
                })
    except Exception as e:
        print(f"错误: 无法解析文本 - {e}", file=sys.stderr)
    
    return posts

def parse_social_html(filepath):
    """解析 HTML 格式社交媒体内容"""
    posts = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 简单正则提取
        # 实际应该用专业的 HTML 解析库
        pattern = r'<div[^>]*class="post"[^>]*>.*?<span class="content">(.+?)</span>.*?<span class="time">(.+?)</span>'
        
        matches = re.findall(pattern, content, re.DOTALL)
        for post_content, timestamp in matches:
            posts.append({
                'content': post_content.strip(),
                'timestamp': timestamp,
                'type': 'text'
            })
    except Exception as e:
        print(f"错误: 无法解析 HTML - {e}", file=sys.stderr)
    
    return posts

def main():
    if len(sys.argv) < 2:
        print("用法: python3 social_parser.py <文件路径>", file=sys.stderr)
        sys.exit(1)
    
    filepath = sys.argv[1]
    file_ext = Path(filepath).suffix.lower()
    
    posts = []
    
    if file_ext == '.txt':
        posts = parse_social_text(filepath)
    elif file_ext == '.html':
        posts = parse_social_html(filepath)
    else:
        # 尝试当作文本处理
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            posts = parse_social_text(filepath)
        except:
            print(f"错误: 无法处理文件 - {filepath}", file=sys.stderr)
            sys.exit(1)
    
    output = {
        'source': 'Social Media',
        'total_posts': len(posts),
        'posts': posts
    }
    
    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

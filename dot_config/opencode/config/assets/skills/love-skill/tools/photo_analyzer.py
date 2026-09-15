#!/usr/bin/env python3
"""
照片分析工具
提取照片 EXIF 和基本视觉信息
"""

import sys
import json
from pathlib import Path

def extract_exif(image_path):
    """提取照片 EXIF 信息"""
    exif_data = {}
    try:
        from PIL import Image
        from PIL.ExifTags import TAGS
        
        img = Image.open(image_path)
        exif = img._getexif()
        
        if exif:
            for tag_id, value in exif.items():
                tag = TAGS.get(tag_id, tag_id)
                exif_data[tag] = str(value)[:200]  # 限制长度
    except ImportError:
        print("警告: PIL 未安装，无法提取照片 EXIF", file=sys.stderr)
    except Exception as e:
        print(f"警告: 无法读取 EXIF - {e}", file=sys.stderr)
    
    return exif_data

def analyze_image(image_path):
    """分析照片基本信息"""
    try:
        from PIL import Image
        
        img = Image.open(image_path)
        
        return {
            'format': img.format,
            'size': f"{img.width}x{img.height}",
            'mode': img.mode
        }
    except:
        return {
            'format': 'unknown',
            'size': 'unknown',
            'mode': 'unknown'
        }

def main():
    if len(sys.argv) < 2:
        print("用法: python3 photo_analyzer.py <图片路径>", file=sys.stderr)
        sys.exit(1)
    
    image_path = sys.argv[1]
    
    if not Path(image_path).exists():
        print(f"错误: 文件不存在 - {image_path}", file=sys.stderr)
        sys.exit(1)
    
    # 提取信息
    basic_info = analyze_image(image_path)
    exif_data = extract_exif(image_path)
    
    output = {
        'source': 'Photo',
        'file': Path(image_path).name,
        'basic_info': basic_info,
        'exif': exif_data
    }
    
    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()

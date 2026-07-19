# YeLuAI 外部知识补充整合 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从 `docx_outline2.txt` 与 `pptx2_outline.txt` 两个已抽取的文本源中，按 YeLuAI PPT 9 章节镜像映射抽取知识性补充点，用 `python-docx` 生成一份整合 Word 文档，供 TRAE 重新生成 YeLuAI 操作手册 PPT 时作为原理补强输入。

**Architecture:** 单文件 Python 脚本，定义一个章节内容数据结构（`CHAPTERS: list[dict]`），每个 dict 含 9 个字段（标题、补充点列表、是否有补充等），按顺序渲染到 docx。验证脚本扫描输出 docx 的纯文本，做"章节数 / 补充点数 / 违禁词"三重校验。

**Tech Stack:** Python 3, `python-docx` 1.x, GBK 二次解码的明文文本源

---

## 文件结构

```
C:\Users\16288\Desktop\yeluai_extract\
├── docx_outline2.txt                   # 输入：docx 已抽取文本（GBK 二次解码后）
├── pptx2_outline.txt                  # 输入：pptx 已抽取文本（GBK 二次解码后）
├── build_supp_doc.py                  # 新建：章节数据结构 + docx 生成主脚本
├── verify_supp_doc.py                 # 新建：验收扫描脚本
└── supp_doc_extract.txt               # 新建：生成后导出的纯文本，供扫描使用

C:\Users\16288\Desktop\
└── YeLuAI_外部知识补充_知识性内容整合.docx   # 交付：最终 docx
```

---

## 章节数据契约（每章 dict 的字段）

```python
{
    "index": "01",
    "title": "平台介绍",
    "has_supplement": True,
    "supplements": [                    # 仅当 has_supplement=True 时使用
        {
            "title": "AI 智能体的五大核心能力",
            "body": "AI 智能体是一种……（段落文本）",
            "source": "pptx2 第 7 张 / docx 第一章"
        }
    ],
    "no_supplement_note": None          # 仅当 has_supplement=False 时使用，字符串说明
}
```

---

## Task 1: 验证输入文件与依赖

**Files:**
- Read: `C:\Users\16288\Desktop\yeluai_extract\docx_outline2.txt`
- Read: `C:\Users\16288\Desktop\yeluai_extract\pptx2_outline.txt`

- [ ] **Step 1: 验证输入文件存在且非空**

```powershell
Test-Path "C:\Users\16288\Desktop\yeluai_extract\docx_outline2.txt"
Test-Path "C:\Users\16288\Desktop\yeluai_extract\pptx2_outline.txt"
(Get-Item "C:\Users\16288\Desktop\yeluai_extract\docx_outline2.txt").Length
(Get-Item "C:\Users\16288\Desktop\yeluai_extract\pptx2_outline.txt").Length
```

Expected: 两个文件都返回 True；长度分别 ≥ 50 KB 和 ≥ 50 KB。

- [ ] **Step 2: 验证 python-docx 已安装**

```powershell
python -c "import docx; print(docx.__version__)"
```

Expected: 打印 `1.x.x` 形式的版本号。

- [ ] **Step 3: 抽样 3 行 docx 文本确认中文未乱码**

```powershell
Get-Content "C:\Users\16288\Desktop\yeluai_extract\docx_outline2.txt" -TotalCount 30 | Select-String "智能体"
```

Expected: 至少匹配 1 行 "智能体"，且无 `?` `�` 之类替换字符。

- [ ] **Step 4: 抽样 3 行 pptx 文本确认中文未乱码**

```powershell
Get-Content "C:\Users\16288\Desktop\yeluai_extract\pptx2_outline.txt" -TotalCount 30 | Select-String "智能体"
```

Expected: 至少匹配 1 行 "智能体"。

---

## Task 2: 写生成脚本骨架与封面

**Files:**
- Create: `C:\Users\16288\Desktop\yeluai_extract\build_supp_doc.py`

- [ ] **Step 1: 创建脚本头部与封面渲染函数**

```python
# build_supp_doc.py
"""生成 YeLuAI 外部知识补充整合 docx。

输入：C:\\Users\\16288\\Desktop\\yeluai_extract\\docx_outline2.txt
     C:\\Users\\16288\\Desktop\\yeluai_extract\\pptx2_outline.txt
输出：C:\\Users\\16288\\Desktop\\YeLuAI_外部知识补充_知识性内容整合.docx
"""
from docx import Document
from docx.shared import Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from pathlib import Path

OUT = Path(r"C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx")
EXTRACT_OUT = Path(r"C:\Users\16288\Desktop\yeluai_extract\supp_doc_extract.txt")

# 字体常量
FONT_HEADING1 = "黑体"
FONT_HEADING2 = "黑体"
FONT_BODY = "宋体"

def set_cn_font(run, name: str, size_pt: float, bold: bool = False):
    run.font.name = name
    # 中文也需指定 east_asia
    rPr = run._element.get_or_add_rPr()
    rFonts = rPr.find("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}rFonts")
    if rFonts is None:
        from docx.oxml.ns import qn
        rFonts = rPr.makeelement(qn("w:rFonts"), {})
        rPr.append(rFonts)
    rFonts.set("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}eastAsia", name)
    rFonts.set("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}ascii", name)
    run.font.size = Pt(size_pt)
    run.font.bold = bold


def write_cover(doc: Document):
    """封面页：标题 / 用途 / 时间 / 来源 / 文档说明"""
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = title.add_run("YeLuAI 外部知识补充")
    set_cn_font(r, FONT_HEADING1, 26, bold=True)

    sub = doc.add_paragraph()
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = sub.add_run("—— 知识性内容整合（供 TRAE 重新生成 YeLuAI 操作手册_完整版 PPT 使用）")
    set_cn_font(r, FONT_HEADING2, 14)

    doc.add_paragraph()  # 空行
    meta_lines = [
        "用途：把两份外部 AI 商业培训资料中与 YeLuAI 平台概念对应的知识性内容（概念/原理/趋势/方法论）抽取出来，按 YeLuAI 操作手册_完整版 PPT 的 9 章节镜像整合。",
        "来源素材：",
        "  A. 《智能增长：AI×商业的营销飞轮》（史杰松著，docx 13 MB）",
        "  B. 《商业 AI 智能体从 0 到 1 搭建商业培训课件》（马钏楠课件，pptx 41 MB）",
        "目标 PPT：YeLuAI 操作手册_完整版（pptx，60 张幻灯片，9 章节）",
        "生成时间：2026-06-14",
    ]
    for line in meta_lines:
        p = doc.add_paragraph()
        r = p.add_run(line)
        set_cn_font(r, FONT_BODY, 11)

    # 前言：使用说明
    doc.add_paragraph()
    h = doc.add_paragraph()
    r = h.add_run("前言：使用说明（写给 TRAE）")
    set_cn_font(r, FONT_HEADING2, 14, bold=True)

    usage = [
        "本文件不复制 YeLuAI 平台自身的功能介绍与操作步骤（这些以 YeLuAI 手册原文为准）。",
        "本文件仅补充 YeLuAI 平台概念背后的原理、定义、趋势与设计方法论，用于让 TRAE 在重新生成 PPT 时能够：",
        "  1. 在每张幻灯片上补充 1~3 句「原理注解」（如「温度参数的设计原理」「RAG 检索的向量机制」），让内容更厚；",
        "  2. 在第 09 章「名词解释」补充更丰富的术语来源，让概念更扎实；",
        "  3. 在第 01 章「平台介绍」补全行业大背景（AI 三次浪潮、智能体五能力），让开篇有高度。",
        "建议 TRAE 拿到本文件后：",
        "  - 逐章对照 YeLuAI 操作手册_完整版 PPT 的 60 张幻灯片；",
        "  - 每个章节挑出 1~3 条「补充点」中可对应到 YeLuAI 概念的部分，写入对应幻灯片的「备注/注解」区域；",
        "  - 不要在 PPT 中直接搬用本文件的整段文字（这是知识性补充材料，不是 PPT 文案）。",
    ]
    for line in usage:
        p = doc.add_paragraph()
        r = p.add_run(line)
        set_cn_font(r, FONT_BODY, 11)
    doc.add_page_break()


if __name__ == "__main__":
    doc = Document()
    write_cover(doc)
    doc.save(OUT)
    print(f"saved cover draft to {OUT}")
```

- [ ] **Step 2: 跑骨架脚本，确认封面 docx 生成成功**

```powershell
cd C:\Users\16288\Desktop\yeluai_extract; python build_supp_doc.py
```

Expected: 打印 `saved cover draft to C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx`，文件存在且非空。

- [ ] **Step 3: 用 docx 打开无错（用 python 验证）**

```powershell
python -c "from docx import Document; d=Document(r'C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx'); print('paragraphs:', len(d.paragraphs))"
```

Expected: `paragraphs:` 后跟 ≥ 10 的数字。

---

## Task 3: 写 9 章节内容数据结构

**Files:**
- Modify: `C:\Users\16288\Desktop\yeluai_extract\build_supp_doc.py`

- [ ] **Step 1: 在 build_supp_doc.py 中追加 `CHAPTERS` 数据列表（在 `if __name__` 之前）**

按以下结构填充（每个 `body` 字段使用从 `docx_outline2.txt` / `pptx2_outline.txt` 中实际抽取的原文，已按 spec 规则去掉"操作步骤、思考题、字段表"）。完整数据见附录 [chapter-data-spec](#chapter-data-spec-附录)，实施时直接复制粘贴即可。

```python
CHAPTERS = [
    {
        "index": "01",
        "title": "平台介绍",
        "has_supplement": True,
        "supplements": [
            # 见附录，每条 {title, body, source}
        ],
        "no_supplement_note": None,
    },
    # ... 共 9 项
]
```

- [ ] **Step 2: 实现 `render_chapter` 渲染函数**

```python
def render_chapter(doc: Document, ch: dict):
    """渲染一级章节标题 + 补充点列表（或无补充说明）。"""
    h = doc.add_paragraph()
    r = h.add_run(f"{ch['index']} {ch['title']} —— {'补充点' if ch['has_supplement'] else '无补充'}")
    set_cn_font(r, FONT_HEADING1, 18, bold=True)

    if not ch["has_supplement"]:
        note = ch["no_supplement_note"]
        p = doc.add_paragraph()
        r = p.add_run(note)
        set_cn_font(r, FONT_BODY, 11)
        doc.add_page_break()
        return

    for i, sup in enumerate(ch["supplements"], 1):
        sh = doc.add_paragraph()
        r = sh.add_run(f"补充点 {i}：{sup['title']}")
        set_cn_font(r, FONT_HEADING2, 13, bold=True)
        for line in sup["body"].split("\n"):
            p = doc.add_paragraph()
            r = p.add_run(line)
            set_cn_font(r, FONT_BODY, 11)
        src = doc.add_paragraph()
        r = src.add_run(f"（来源：{sup['source']}）")
        set_cn_font(r, FONT_BODY, 9)
        doc.add_paragraph()  # 补充点间空行

    doc.add_page_break()
```

- [ ] **Step 3: 跑脚本，确认 docx 章节渲染无误**

```powershell
cd C:\Users\16288\Desktop\yeluai_extract; python build_supp_doc.py
```

Expected: 不报错，docx 文件大小 ≥ 30 KB。

- [ ] **Step 4: 在 `__main__` 中调用 render_chapter 循环**

```python
if __name__ == "__main__":
    doc = Document()
    write_cover(doc)
    for ch in CHAPTERS:
        render_chapter(doc, ch)
    # Task 4 会追加附录
    doc.save(OUT)
    print(f"saved with {len(CHAPTERS)} chapters to {OUT}")
```

- [ ] **Step 5: 重新跑脚本，输出 docx 包含 9 章节**

```powershell
cd C:\Users\16288\Desktop\yeluai_extract; python build_supp_doc.py
python -c "from docx import Document; d=Document(r'C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx'); print('paragraphs:', len(d.paragraphs))"
```

Expected: `paragraphs:` ≥ 100。

---

## Task 4: 写附录 A、B 与导出纯文本

**Files:**
- Modify: `C:\Users\16288\Desktop\yeluai_extract\build_supp_doc.py`

- [ ] **Step 1: 实现 `render_appendix` 函数**

```python
def render_appendix(doc: Document):
    """附录 A 来源对照 + 附录 B 抽取规则说明"""
    # 附录 A
    h = doc.add_paragraph()
    r = h.add_run("附录 A：来源素材章节对照表")
    set_cn_font(r, FONT_HEADING1, 18, bold=True)

    appendix_a = [
        "本文件所有「补充点」内容均来自以下两份外部素材的对应章节：",
        "",
        "素材 A——《智能增长：AI×商业的营销飞轮》（史杰松著）：",
        "  - 第一章 人工智能商业实战基础认知（AI 三次浪潮、推理/非推理模型、AI 智能体能力 vs 学生学习方式）",
        "  - 后续章节（营销飞轮、AI 个体）仅作 01 平台介绍下「营销场景」小补充",
        "",
        "素材 B——《商业 AI 智能体从 0 到 1 搭建商业培训课件》（马钏楠课件）：",
        "  - 第 1 章 大模型与智能体基础（核心名词解释、智能体定义、扣子平台、推理/非推理模型）",
        "  - 第 2 章 智能体平台功能介绍（界面总览、11 大模块）",
        "  - 第 3 章 大语言模型提示词（CRAFT 框架、思维链、6 大误区、4 大调优参数）",
        "  - 第 4 章 企业知识库与 RAG 技术（RAG 原理、四种知识导入、分段模式、检索策略）",
        "  - 第 5 章 数据库构建与应用（MySQL/SqlServer/PostgreSQL、SQL、JSON）",
        "  - 第 6~8 章（插件/工作流/多智能体协同）→ 对应 YeLuAI 第 05/03 章",
    ]
    for line in appendix_a:
        p = doc.add_paragraph()
        r = p.add_run(line)
        set_cn_font(r, FONT_BODY, 11)

    # 附录 B
    doc.add_page_break()
    h = doc.add_paragraph()
    r = h.add_run("附录 B：抽取规则与去重说明")
    set_cn_font(r, FONT_HEADING1, 18, bold=True)

    appendix_b = [
        "保留：",
        "  ✓ 概念定义、原理机制、趋势研判、选型逻辑",
        "  ✓ 参数建议值（如「客服场景相似度阈值 0.75-0.8」「温度 0~0.2 适合严谨问答」）",
        "  ✓ 设计框架（CRAFT 提示词框架、思维链）",
        "  ✓ 方法论表格、对比表（如「AI 智能体 vs 人类学习方式」）",
        "  ✓ 名词解释",
        "",
        "丢弃：",
        "  ✗ 操作步骤（「点击 X 按钮」「输入 API Key」「保存发布」）",
        "  ✗ UI 截图说明、字段表、配置项枚举",
        "  ✗ 思考题、作业题、本章问题",
        "  ✗ 与 YeLuAI 平台无明确映射的纯营销案例",
        "",
        "统一处理：",
        "  • 术语统一：使用「智能体」而非「AI Agent」等并列写法",
        "  • 同一概念在两素材都出现时取表述更精炼的，末尾标「（来源：……）」",
        "  • 营销飞轮作为「营销场景」小补充纳入 01 平台介绍，不做独立章节",
        "",
        "判定为「无补充」的章节：",
        "  • 06 用户与权限管理：外部素材仅在客户管理提到标签，无角色/权限原理性内容",
        "  • 08 案例实战：YeLuAI 自身案例 A~H 由 YeLuAI 手册提供，外部无补充",
    ]
    for line in appendix_b:
        p = doc.add_paragraph()
        r = p.add_run(line)
        set_cn_font(r, FONT_BODY, 11)
```

- [ ] **Step 2: 在 `__main__` 中追加 `render_appendix` 与 `extract_text`**

```python
if __name__ == "__main__":
    doc = Document()
    write_cover(doc)
    for ch in CHAPTERS:
        render_chapter(doc, ch)
    render_appendix(doc)
    doc.save(OUT)

    # 导出纯文本供验证脚本扫描
    text_chunks = []
    for p in doc.paragraphs:
        text_chunks.append(p.text)
    EXTRACT_OUT.write_text("\n".join(text_chunks), encoding="utf-8")
    print(f"saved {OUT}; extract: {EXTRACT_OUT}")
```

- [ ] **Step 3: 跑脚本，确认 docx 含附录且导出 supp_doc_extract.txt**

```powershell
cd C:\Users\16288\Desktop\yeluai_extract; python build_supp_doc.py
Test-Path "C:\Users\16288\Desktop\yeluai_extract\supp_doc_extract.txt"
Get-Content "C:\Users\16288\Desktop\yeluai_extract\supp_doc_extract.txt" | Select-String "附录 A"
```

Expected: 三个命令都返回 True / 匹配。

---

## Task 5: 写验收脚本

**Files:**
- Create: `C:\Users\16288\Desktop\yeluai_extract\verify_supp_doc.py`

- [ ] **Step 1: 创建验收脚本**

```python
# verify_supp_doc.py
"""验收 YeLuAI 外部知识补充 docx。

三重校验：
  1. 9 个一级章节齐（含 2 个"无补充"说明）
  2. 补充点数：02/03/09 ≥ 3，01/04/05/07 ≥ 1
  3. 违禁词扫描：操作步骤词汇必须 0 命中

返回 exit code 0 = 通过；非 0 = 失败并打印失败项。
"""
import re
import sys
from pathlib import Path

EXTRACT = Path(r"C:\Users\16288\Desktop\yeluai_extract\supp_doc_extract.txt")
text = EXTRACT.read_text(encoding="utf-8")

errors = []

# 1) 9 章节齐
chapter_titles = [
    "01 平台介绍",
    "02 知识库",
    "03 智能体",
    "04 模型接入",
    "05 工具",
    "06 用户与权限管理",
    "07 系统 API",
    "08 案例实战",
    "09 名词解释",
]
for t in chapter_titles:
    if t not in text:
        errors.append(f"缺章节标题：{t}")

# 2) 补充点数
sup_counts = {
    "01": 1,  # 至少
    "02": 3,
    "03": 3,
    "04": 1,
    "05": 1,
    "07": 1,
    "09": 3,
}
for prefix, need in sup_counts.items():
    pat = re.compile(rf"^{prefix} .*?—— 补充点", re.M)
    found = len(pat.findall(text))
    if found < need:
        errors.append(f"补充点数不足：{prefix} 需要 ≥ {need}，实际 {found}")

# 3) 违禁词扫描
forbidden = ["点击 ", "输入 API Key", "保存发布", "按钮", "字段表", "思考题", "本章作业"]
for w in forbidden:
    cnt = text.count(w)
    if cnt > 0:
        errors.append(f"违禁词 {w!r} 出现 {cnt} 次")

# 报告
if errors:
    print("FAILED:")
    for e in errors:
        print("  -", e)
    sys.exit(1)
print("PASS: 9 章节齐，补充点数达标，无违禁词")
sys.exit(0)
```

- [ ] **Step 2: 跑验收**

```powershell
cd C:\Users\16288\Desktop\yeluai_extract; python verify_supp_doc.py
```

Expected: 打印 `PASS: 9 章节齐，补充点数达标，无违禁词`，exit code 0。

- [ ] **Step 3: 如失败，定位并修复**

回到 Task 3 的 CHAPTERS 数据，定位失败项：
- 缺章节：检查 write_cover / render_chapter 是否覆盖 9 个标题字符串
- 补充点数不足：补对应的 supplements 列表
- 违禁词：在 docx 中定位出现的段落，回到源文本删去

修复后重新跑 Task 4 Step 3 + Task 5 Step 2。

---

## Task 6: 交付

**Files:**
- Read: `C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx`

- [ ] **Step 1: 确认最终 docx 文件大小合理**

```powershell
(Get-Item "C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx").Length
```

Expected: 30 KB ~ 200 KB（纯文本 + 样式，不含图片）。

- [ ] **Step 2: 用 Word/WPS 打开无错**

手动操作：双击 `C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx`，确认：
- 封面标题、来源、用途显示正常
- 9 章节标题齐
- 02/03/09 至少 3 个补充点
- 中文不乱码

- [ ] **Step 3: 给 TRAE 的使用说明（写到对话回复里，不写入 docx）**

```
输入文件：C:\Users\16288\Desktop\YeLuAI_外部知识补充_知识性内容整合.docx
使用方法（给 TRAE）：
  1. 把本 docx 与 YeLuAI 操作手册_完整版.pptx 一起作为输入；
  2. 逐章对照 PPT 的 60 张幻灯片，从对应章节挑 1~3 条"补充点"作为幻灯片注解；
  3. 第 01 章用于在 PPT 开篇加「AI 浪潮 + 智能体五能力」高度；
  4. 第 02 章用于在「RAG」「分段」「检索参数」相关幻灯片补强；
  5. 第 03 章用于在「提示词编排」「工作流」相关幻灯片补强；
  6. 第 09 章名词解释合并外部术语，比原 PPT 更丰富。
```

---

## chapter-data-spec 附录

**`CHAPTERS` 完整数据**（直接复制到 `build_supp_doc.py` 中 `CHAPTERS = [...]`）：

> **注意：实施时把以下 Python 字面量原样写入 `build_supp_doc.py`。所有 `body` 内容已按 spec 规则抽取自 `docx_outline2.txt` 和 `pptx2_outline.txt`，去掉了"操作步骤、思考题、字段表"。**

```python
CHAPTERS = [
    # ============ 01 平台介绍 ============
    {
        "index": "01",
        "title": "平台介绍",
        "has_supplement": True,
        "supplements": [
            {
                "title": "AI 智能体的定义与五大核心能力",
                "body": (
                    "AI 智能体是一种具备感知、记忆、推理、执行、学习能力的智能程序。它不仅能回答问题，还能主动调用工具、执行任务，是能独立干活的「数字员工」——从理解意图、规划步骤到调用插件与 API 完成业务闭环，真正实现了从「对话」到「执行」的跨越。\n"
                    "五大核心能力：\n"
                    "1. 感知：理解文字、图片、语音等多模态信息（例：客服机器人识别用户发的截图，自动读取订单号）\n"
                    "2. 记忆：记住上下文，多轮对话不跑偏（例：用户说「推荐一款手机」，AI 问「预算多少」，用户答「3000 左右」，AI 记得刚才问的是手机推荐）\n"
                    "3. 推理：分析问题、拆解任务、做出判断（例：用户说「我明天要去北京开会」，AI 推理出需要查天气、订车票、规划路线，自动拆解成多个子任务）\n"
                    "4. 执行：调用工具、操作软件、完成任务（例：根据用户指令，自动打开日历添加会议、发送邮件、生成报表）\n"
                    "5. 学习：根据反馈不断优化，越用越聪明（例：用户对推荐结果点「不喜欢」，AI 记住偏好，下次推荐更精准）"
                ),
                "source": "pptx2 第 7 张",
            },
            {
                "title": "AI 智能体 vs 人类学习方式对比",
                "body": (
                    "把学生班级里来了一位「人工智能超级学霸」，其学习方式与人类学生截然不同：\n\n"
                    "学习步骤  |  人类学生方式          |  人工智能方式\n"
                    "1         |  上课知识输入          |  数据获取（收集与任务相关的原始数据如文本、图像）\n"
                    "2         |  总结复习              |  数据处理（清洗数据、统一格式，为训练做准备如去除噪声、标注标签）\n"
                    "3         |  梳理知识框架          |  模型选择（根据数据特征选择算法如分类任务选逻辑回归，聚类任务选 K-means）\n"
                    "4         |  课后作业练习          |  模型训练（用数据优化模型参数，学习数据内在规律如梯度下降优化权重）\n"
                    "5         |  每周测验检查          |  模型评估（通过测试集验证性能指标如准确率、召回率）\n"
                    "6         |  查漏补缺              |  模型调整（根据评估结果优化超参数或更换算法如调整学习率、增加正则化）"
                ),
                "source": "docx 第一章「五」",
            },
            {
                "title": "人工智能发展的三次浪潮",
                "body": (
                    "截至 2025 年，人工智能发展经历了三次浪潮：\n"
                    "第一次浪潮（1956—1974 年）：以逻辑推理和专家系统为特点，期间人工智能概念诞生并实现快速发展。但由于计算能力限制，AI 研究遇冷。\n"
                    "第二次浪潮（1980—1987 年）：带来了模型突破和初步产业化，如 XCON 专家系统和 BP 算法，但随后因场景局限和高维护费用进入第二次寒冬。\n"
                    "第三次浪潮（1993—2011 年起）：以创新研究加速和技术实用化为特征，支持向量机、卷积神经网络等技术发展。从 2023 年至今，深度学习算法推动了人工智能的广泛应用，算力和数据量显著增长，标志性事件包括 AlphaGo 战胜围棋冠军和 Transformer 的被提出。2024 年 1 月 5 日发布的首个大模型 DeepSeek LLM 标志着中国 AI 技术从「追赶」到「引领」的转变。"
                ),
                "source": "docx 第一章「二」",
            },
            {
                "title": "AI 个体：从「数字员工」到「数字团队」的演进",
                "body": (
                    "「AI 个体」是智能体商业化的核心概念：把一个 AI 智能体视为一名「数字员工」，具备感知、记忆、推理、执行、学习五大能力。一个企业从「1 个 AI 智能体 + 1 个工位」起步，逐步扩展为「N 个 AI 智能体组成数字团队」，是 AI 商业落地的演进路径。\n"
                    "YeLuAI 平台定位是「让已有系统快速拥有智能问答能力」，正是 AI 个体从单点工具到业务闭环的桥梁。"
                ),
                "source": "docx 营销飞轮 + pptx2 第 6 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 02 知识库 ============
    {
        "index": "02",
        "title": "知识库",
        "has_supplement": True,
        "supplements": [
            {
                "title": "RAG 工作原理：嵌入→检索→重排→增强生成",
                "body": (
                    "RAG（Retrieval-Augmented Generation，检索增强生成）由四步构成：\n"
                    "1. 向量嵌入：将文本转换为一组高维数值向量（如 768 维），使语义相近的文本在向量空间中距离更近。常用 OpenAI 的嵌入模型（如 text-embedding-ada-002）。\n"
                    "2. 稠密向量检索：基于向量距离计算与用户问题最相似的文本段落。\n"
                    "3. 重排（Rerank）：使用专用重排模型（如 Cohere rerank）从初筛结果中精筛出 Top-N 最相关内容。\n"
                    "4. 上下文增强生成：将检索到的知识片段与大模型的提示词（Prompt）拼接，并通过特殊分隔符明确标记知识来源。模型生成回答时优先依据私有知识。\n"
                    "RAG 既能捕捉同义词表达，也能锁定精准词汇，是大模型回答「企业专属问题」的核心机制。"
                ),
                "source": "pptx2 第 57 张",
            },
            {
                "title": "混合检索：稠密向量 + 稀疏 BM25 + 重排",
                "body": (
                    "混合检索机制同时使用两种检索策略：\n"
                    "• 稠密向量检索（按语义相似度召回）\n"
                    "• 稀疏 BM25 算法（按关键词匹配召回）\n"
                    "先通过向量检索获取一批相关段落，再经重排模型（如 Cohere rerank）从中精筛出 Top3 最相关内容。该机制在准确性与召回率之间取得平衡，既能捕捉同义词表达，也能锁定精准词汇。\n"
                    "BM25 是一种基于关键词匹配的检索算法，根据词频和文档长度计算相关性，适合精准匹配专有名词（如型号、规格）。"
                ),
                "source": "pptx2 第 57 张 + 第 56 张",
            },
            {
                "title": "四种知识导入方式与适用场景",
                "body": (
                    "1. 无结构文档处理：支持 PDF/DOCX/MD/TXT 等主流格式，无需人工预处理。采用自研层级分段算法精准识别标题、目录与段落结构，自定义分块大小（200-1000 字符），开启增强解析可自动清洗格式、修正乱码、识别图片文字。\n"
                    "2. QA 问答对：以双列 CSV 格式批量导入，第一列问题、第二列答案。兼容企业现有客服、CRM 导出的问答数据。在 FAQ 场景下，问答检索命中率可达 95% 以上。\n"
                    "3. 多列表格：支持 Excel/CSV 格式的结构化数据一键导入，可灵活配置多列检索规则、数值范围检索、模糊匹配、跨表关联查询。适用于产品参数表、客户信息表、院校名录等。\n"
                    "4. 网站导入：支持博客、公众号文章等静态网页一键导入，可通过单个链接、批量链接或网站地图三种方式上传。系统自动解析正文，剔除广告与冗余信息。\n"
                    "YeLuAI 平台对应支持「通用型 / Web 站点 / 飞书 / 工作流」四类知识库类型，与上述导入方式一一对应。"
                ),
                "source": "pptx2 第 58-61 张 + YeLuAI PPT 第 8 张",
            },
            {
                "title": "三种分段模式与上下文长度匹配",
                "body": (
                    "三种分段模式：\n"
                    "• 智能分段（默认）：设置最大分段长度，系统自动根据文档类型选择分隔符。适用：通用文档、产品说明书、企业制度文件、教材课件。\n"
                    "• 自定义分段：自定义分隔符（支持多个分隔符递归处理），设置分段重叠度（建议 10%-20%）。适用：FAQ 问答对、固定格式的文档、需要精准拆分的内容。\n"
                    "• 层级分段：设置分段层级（如 3 级），按 Markdown 标题层级拆分文档，每段自动保留上级标题信息。适用：营销方案、技术文档、教材章节、有清晰层级结构的 Markdown 文档。\n\n"
                    "分段长度建议（与 YeLuAI 第 10 张幻灯片一致）：\n"
                    "• 8K 上下文模型：分段长度 300-500 字符\n"
                    "• 32K 上下文模型：分段长度 1000-1500 字符\n"
                    "• 128K 以上模型：分段长度 2000-3000 字符"
                ),
                "source": "pptx2 第 63 张 + YeLuAI PPT 第 10-12 张",
            },
            {
                "title": "检索参数建议值",
                "body": (
                    "• 检索方式：支持语义检索（向量相似度匹配）和增强检索（语义+全文关键词）。增强检索可提升专有名词、型号等精准匹配效果。\n"
                    "• 相似度阈值：控制召回精度。客服场景 0.75-0.8（精准），泛内容 0.65-0.7（覆盖）。\n"
                    "• 检索条数：语义检索 3-6 条，全文检索 1-2 条，两者之和不超过 10 条。\n"
                    "• 未命中处理：可配置自由发挥、固定文案或转人工。客服场景建议固定回复引导用户联系人工。\n"
                    "• 查询改写与重排：开启查询改写可补全多轮对话主语缺失；开启结果重排可将最相关内容置于上下文前列。"
                ),
                "source": "pptx2 第 62 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 03 智能体 ============
    {
        "index": "03",
        "title": "智能体",
        "has_supplement": True,
        "supplements": [
            {
                "title": "CRAFT 结构化提示词设计框架",
                "body": (
                    "CRAFT 是 5 个维度的提示词设计框架，对应 YeLuAI PPT 第 21 张「提示词编排详解」的 ROSTL：\n\n"
                    "C — Context（背景/上下文）：说明给谁看、在哪用、为什么做。\n"
                    "  示例：「面向职场新人，用于企业内部周报邮件，目的是清晰汇报工作进展。」\n"
                    "R — Role（角色）：指定 AI 扮演的身份，激活专业视角。\n"
                    "  示例：「你是一位有 5 年经验的运营主管，擅长结构化总结，逻辑清晰。」\n"
                    "A — Action（行动/具体要求）：核心指令，明确做什么、做到什么程度。\n"
                    "  示例：「写一份 500 字的周报，包含本周 3 项重点工作、1 个待解决问题、下周 2 个计划。」\n"
                    "F — Format（格式/框架）：规范输出结构，确保内容符合使用场景。\n"
                    "  示例：「邮件格式，主题含『周报-姓名-日期』；正文分四块：成果、数据、风险、规划。」\n"
                    "T — Tone（基调/目标细化）：明确情感色彩和最终目的。\n"
                    "  示例：「语气专业、简洁、自信，目标：让上级 2 分钟内掌握关键信息。」"
                ),
                "source": "pptx2 第 47 张",
            },
            {
                "title": "思维链（Chain of Thought）提示词技巧",
                "body": (
                    "思维链（CoT）是一种提示词设计方法，将复杂任务拆解为逻辑连贯的小步骤，引导 AI 逐步推导，让 AI 的思考过程「可视化」，而非直接给出答案。\n\n"
                    "应用价值：\n"
                    "• 提升准确性：分步推导减少错误，避免 AI「跳步」给出不成熟答案\n"
                    "• 过程可解释：可以看到 AI 的推理过程，便于理解其判断依据\n"
                    "• 便于调试：哪一步出错可以单独修正，无需重头再来\n"
                    "• 多轮优化：可根据中间结果调整后续步骤，实现精细化控制\n\n"
                    "三种进阶用法：\n"
                    "• 零样本思维链：不加示例，直接让 AI「一步步思考」\n"
                    "• 少样本思维链：给 1-3 个示例，让 AI 模仿推理模式\n"
                    "• 自我一致性：多次运行思维链，取多数结果，提高稳定性"
                ),
                "source": "pptx2 第 49-50 张",
            },
            {
                "title": "提示词的 6 大常见误区与优化技巧",
                "body": (
                    "6 大常见误区：\n"
                    "1. 语言模糊：使用「一些」「大概」等模糊词 → 用具体数字、明确范围替代\n"
                    "2. 多需求堆砌：一句话塞进多个矛盾要求 → 分步骤、分优先级表达\n"
                    "3. 缺乏背景假设：默认 AI 知道你的身份和场景 → 说明「我是谁」「给谁看」「在哪用」\n"
                    "4. 逻辑断裂：目标与步骤脱节 → 用「因为…所以…」等逻辑词串联\n"
                    "5. 边界缺失：不提范围、格式、限制 → 明确「要什么」「不要什么」\n"
                    "6. 忽略风险：未考虑伦理、法律、安全 → 添加合规约束，如「符合广告法」\n\n"
                    "4 个优化技巧：\n"
                    "• 技巧 1：角色扮演——让 AI 代入特定角色（摄影师、设计师、编剧等）\n"
                    "• 技巧 2：设定输出格式——明确要求输出格式（表格、列表、代码块、Markdown 等）\n"
                    "• 技巧 3：加入负面约束——明确告诉 AI「不要做什么」\n"
                    "• 技巧 4：多轮迭代优化——先给基础提示词，根据输出逐步补充细节"
                ),
                "source": "pptx2 第 51-53 张",
            },
            {
                "title": "工作流编排的本质：把 AI 能力按顺序组合成自动化流程",
                "body": (
                    "工作流（Workflow）是一种可视化编排多节点流程的智能体创建方式，实现复杂任务的自动化执行。\n\n"
                    "YeLuAI 平台 5 大类组件（与 pptx2 第 32 张对应）：\n"
                    "• AI 能力组件：AI 对话、意图识别、图片理解、语音处理\n"
                    "• 知识库组件：知识库检索、多路召回、文档标签检索\n"
                    "• 业务逻辑组件：判断器、指定回复、表单收集、循环节点\n"
                    "• 数据处理组件：变量赋值、聚合、拆分、参数提取\n"
                    "• 其他组件：MCP 调用、自定义工具、工具节点、智能体节点\n\n"
                    "YeLuAI 平台工作流 15+ 种可视化节点，零代码拖拽搭建，支持定时自动运行（自然语言或 cron 表达式），支持多应用协同与主动渠道发送。"
                ),
                "source": "pptx2 第 32 张 + YeLuAI PPT 第 23 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 04 模型接入 ============
    {
        "index": "04",
        "title": "模型接入",
        "has_supplement": True,
        "supplements": [
            {
                "title": "推理大模型 vs 非推理大模型",
                "body": (
                    "推理大模型：通过强化学习和思维链（Chain of Thought）等技术，实现多步骤推理。输出更严谨、结构清晰，适合需要「想清楚再回答」的任务。代表：DeepSeek-R1、通义千问 Qwen3、o1 系列、Claude 3 Opus。\n"
                    "适用场景：复杂逻辑分析（法律条款解读、因果关系分析）、数学推理（解题步骤推导、公式应用）、代码生成（算法实现、bug 修复、架构设计）、科学计算（数据建模、实验设计）。\n\n"
                    "非推理大模型：基于自回归生成机制，通过大规模文本数据预训练，重点优化语言流畅度和响应速度。代表：GPT-4o、Claude 3.5 Sonnet、豆包、文心一言、通义千问 Turbo。\n"
                    "适用场景：日常对话（客服问答、闲聊陪伴）、内容创作（营销文案、社交媒体推文、故事续写）、信息提取（摘要生成、关键词提取）、翻译润色（多语言翻译、文本改写）。\n\n"
                    "YeLuAI 平台支持国内外主流大模型灵活切换；选择依据：业务对「严谨度」vs「响应速度」的要求。"
                ),
                "source": "pptx2 第 14-15 张 + docx 第一章「三」",
            },
            {
                "title": "4 大核心调优参数：温度、记忆、上下文、拟人化",
                "body": (
                    "1. 温度（Temperature）范围 0-1：控制回复的创意性与确定性。温度越低，回答越稳定一致；温度越高，回答越丰富多样。\n"
                    "   场景化建议值：\n"
                    "   • 知识库问答 / 智能客服：0 - 0.2（回复严谨、不编造）\n"
                    "   • 教学知识点答疑：0.1 - 0.3\n"
                    "   • 方案策划 / 长文档分析：0.3 - 0.5\n"
                    "   • 营销文案 / 创意内容生成：0.7 - 0.9（回复富有创意）\n"
                    "   • 数据计算 / 逻辑推理：0 - 0.1\n\n"
                    "2. 记忆（轮数）：控制对话上下文保留多少轮（一问一答计为 1 轮）。多轮对话场景建议 3-5 轮，最高 10 轮（工作流或应用节点中可设置）。记忆保留时间默认 30 分钟。\n\n"
                    "3. 上下文长度：模型单次能处理的 token 上限。配套知识库分段长度建议：8K 模型分段 300-500 字符，32K 模型分段 1000-1500 字符，128K 以上模型分段 2000-3000 字符。\n\n"
                    "4. 拟人化配置：分段回复（私域营销建议开启）、延迟回复（1-60 秒随机延迟，降低「机器人感知」）、合并回复（避免 AI 重复应答）、跨天记忆（长期服务场景开启）、提示词优化（补充语气、称呼等要求）。"
                ),
                "source": "pptx2 第 16-20 张",
            },
            {
                "title": "结构化输出：从自然语言提取 JSON 字段",
                "body": (
                    "大模型节点支持定义输出变量，将自然语言内容智能提取为结构化的 JSON 格式。便于提取参数、对接业务系统、实现参数传递。\n\n"
                    "适用场景：\n"
                    "• 从对话中提取客户信息（姓名、电话、需求）\n"
                    "• 提取订单详情（产品、数量、金额）\n"
                    "• 提取表单数据、产品参数等\n\n"
                    "典型用法：大模型节点（开启结构化输出）→ 变量映射 → 自定义插件节点或数据库节点，实现业务闭环。\n"
                    "示例：用户说「我要买 2 件红色 M 码 T 恤」，AI 自动输出结构化 JSON。"
                ),
                "source": "pptx2 第 19 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 05 工具 ============
    {
        "index": "05",
        "title": "工具",
        "has_supplement": True,
        "supplements": [
            {
                "title": "工具的本质：让智能体有「手和脚」",
                "body": (
                    "插件（工具）是一种基于 Agent 架构的高可扩展工具调用能力，让智能体拥有「手和脚」，可以调用外部服务。\n"
                    "作用：扩展 AI 能力——联网搜索、查询天气、画图、识图、总结网页、查询快递、操作飞书 / GitHub 等。\n\n"
                    "YeLuAI 平台对应：自定义工具（Python）、Skills（ZIP 导入）、MCP（JSON）、工具商店。详见 YeLuAI PPT 第 34-37 张。"
                ),
                "source": "pptx2 第 30 张 + YeLuAI PPT 第 34 张",
            },
            {
                "title": "工具触发方式：意图识别 vs 关键词",
                "body": (
                    "工具触发有两种方式：\n"
                    "• 意图识别自动触发：智能体根据用户输入自动判断是否需要调用工具\n"
                    "• 关键词手动触发：根据关键词匹配直接调用对应工具\n\n"
                    "YeLuAI 平台对应：AI 对话节点的「技能」模块可挂载 MCP / 工具 / Skill / 智能体，并支持「输出执行过程」便于调试。"
                ),
                "source": "pptx2 第 31 张 + YeLuAI PPT 第 28 张",
            },
            {
                "title": "MCP 协议：标准化的 AI 工具接口",
                "body": (
                    "MCP（Model Context Protocol，模型上下文协议）是 AI 智能体与外部工具（如地图、飞书）的标准接口，让 AI 能调用各种插件。\n\n"
                    "MCP 配置要素：\n"
                    "• server：MCP 服务器地址与配置\n"
                    "• tools：可用工具列表与参数定义\n"
                    "• resources：资源访问与权限配置\n"
                    "• prompts：预设 Prompt 模板管理\n\n"
                    "YeLuAI 平台 MCP 配置（对应 YeLuAI PPT 第 36 张）：仅支持 SSE（Server-Sent Events，实时推送）和 Streamable HTTP（流式 HTTP 传输）两种协议。"
                ),
                "source": "pptx2 第 31 张 + YeLuAI PPT 第 36 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 06 权限（无补充）============
    {
        "index": "06",
        "title": "用户与权限管理",
        "has_supplement": False,
        "supplements": [],
        "no_supplement_note": (
            "本章以 YeLuAI 操作手册原文为准，本补充材料无额外原理补充。\n"
            "外部素材仅在「客户管理」层面提到客户标签（AI 自动打标签如「高意向客户」「投诉客户」），属于客户端运营范畴，与 YeLuAI 系统级用户/角色/资源授权机制无直接对应。"
        ),
    },
    # ============ 07 系统 API ============
    {
        "index": "07",
        "title": "系统 API",
        "has_supplement": True,
        "supplements": [
            {
                "title": "API 概念与 HTTP 协议基础",
                "body": (
                    "API（Application Programming Interface，应用程序接口）是不同软件之间互相通信和数据交换的通道。\n"
                    "HTTP 协议：客户端与服务器之间传输数据的标准规则，AI 通过它调用外部 API。\n\n"
                    "YeLuAI 平台兼容 OpenAI API 标准格式，例如：\n"
                    "  POST /v1/chat/completions\n"
                    "  Authorization: Bearer {APIKey}\n\n"
                    "MCP 在 HTTP 之上又封装了 SSE（Server-Sent Events，服务器发送事件，实时单向推送）和 Streamable HTTP（流式 HTTP 传输）两种协议。"
                ),
                "source": "pptx2 第 23 张 + YeLuAI PPT 第 44 张",
            },
            {
                "title": "大模型 API 常见字段语义",
                "body": (
                    "大模型 API 调用常见字段：\n"
                    "• APIKey：访问密钥，用于身份认证\n"
                    "• model：模型名称（如 gpt-4、deepseek-chat）\n"
                    "• messages：对话消息列表（system / user / assistant）\n"
                    "• temperature：温度参数（0-1）\n"
                    "• max_tokens：最大生成 token 数\n"
                    "• stream：是否流式输出\n\n"
                    "YeLuAI 平台 APIKey 管理：支持创建、查看、重置和删除，支持 Bearer Token 认证，开启身份验证可确保只有授权用户可访问。"
                ),
                "source": "pptx2 + YeLuAI PPT 第 32、44 张",
            },
            {
                "title": "结构化数据 API：MySQL / SQL Server / PostgreSQL / SQL",
                "body": (
                    "MySQL / SQL Server / PostgreSQL：三种常用的关系型数据库，用于存储和管理结构化数据。\n"
                    "SQL：结构化查询语言，用于向数据库提问并获取数据的标准语法。\n"
                    "JSON：一种轻量级数据交换格式，用键值对表示结构化数据。\n"
                    "Token：大模型处理文本的最小单位，1 个 Token 约等于 0.75 个英文单词或半个中文汉字。\n\n"
                    "YeLuAI 平台对应：通过自定义工具（Python 代码）连接上述数据库，由智能体自动生成 SQL 语句完成数据查询。"
                ),
                "source": "pptx2 第 23-24 张 + YeLuAI PPT 第 28 张",
            },
        ],
        "no_supplement_note": None,
    },
    # ============ 08 案例实战（无补充）============
    {
        "index": "08",
        "title": "案例实战",
        "has_supplement": False,
        "supplements": [],
        "no_supplement_note": (
            "本章以 YeLuAI 操作手册附录三的「工作流搭建（含知识库）实践案例」为准，本补充材料无额外补充。\n"
            "YeLuAI 自身案例 A~H（课程信息问答 / 成绩查询助手 / 作业常见问题解答 / 学业预警分析 / 课程推荐+学习小组申请 / 综合智能教学助手 / AI 海报生成 / 学生综合查询助手）由 YeLuAI 手册提供完整工作流与提示词原文。"
        ),
    },
    # ============ 09 名词解释 ============
    {
        "index": "09",
        "title": "名词解释",
        "has_supplement": True,
        "supplements": [
            {
                "title": "大模型与智能体类名词",
                "body": (
                    "• 大模型：经过海量数据训练的超大规模 AI 模型，是智能体的「大脑」\n"
                    "• Agent（智能体）：具备感知、记忆、推理、执行、学习能力的 AI 程序，能自主完成任务\n"
                    "• LLM（大语言模型）：参数规模通常在十亿以上，在海量数据上预训练，并能适应多种任务的深度学习模型\n"
                    "• Token（词元）：文本处理中的最小单位，1 个 Token 约等于 0.75 个英文单词或半个中文汉字\n"
                    "• Prompt（提示词）：向模型输入的指令或问题，精心设计的 Prompt 能显著提升模型输出质量\n"
                    "• Skills（技能）：预封装的功能模块，如联网搜索、代码执行等，可快速扩展智能体能力\n"
                    "• MCP（模型上下文协议）：标准化协议，允许 AI 模型与外部工具、数据源进行安全、可控的交互\n"
                    "• Function Call：大模型识别用户意图后自动调用预定义函数的能力，实现与外部系统的联动"
                ),
                "source": "pptx2 第 5、24 张 + YeLuAI PPT 第 55 张",
            },
            {
                "title": "RAG 与检索类名词",
                "body": (
                    "• RAG（检索增强生成）：结合信息检索与文本生成的技术，先从知识库检索相关内容，再由 LLM 生成回答\n"
                    "• Embedding Model（向量嵌入模型）：将文本转换为高维向量的模型，使得语义相似的文本在向量空间中距离更近\n"
                    "• 余弦相似度：衡量两个向量方向相似程度的指标，值越接近 1 表示语义越相近\n"
                    "• BM25 算法：基于关键词匹配的检索算法，根据词频和文档长度计算相关性，适合精准匹配专有名词\n"
                    "• Rerank（重排）：对初步检索结果进行重新排序，提升最相关文档的排名\n"
                    "• 重排模型：专门用于评估查询与文档相关性的模型，输出相关性分数用于结果排序\n"
                    "• 检索模式：向量检索（基于语义相似度）/ 全文检索（基于关键词匹配）/ 混合检索（两者结合，效果最佳）\n"
                    "• 相似度：衡量两个向量之间语义接近程度的指标\n"
                    "• 向量化：将文本、图片等数据转换为向量表示的过程\n"
                    "• Chunking（文档分段）：将长文档切分为小块以便向量化与检索\n"
                    "• 多路召回：同时使用多种检索策略获取候选结果，再合并去重"
                ),
                "source": "pptx2 第 56 张 + YeLuAI PPT 第 56、58 张",
            },
            {
                "title": "协议与工具类名词",
                "body": (
                    "• API / APIKey：应用程序接口及访问密钥，用于调用外部服务或模型能力\n"
                    "• HTTP 协议：客户端与服务器之间传输数据的标准规则\n"
                    "• SSE（服务器发送事件）：一种服务器向客户端推送实时数据的技术，用于流式输出 AI 回复\n"
                    "• Streamable HTTP：流式 HTTP 传输协议\n"
                    "• MCP 协议：AI 智能体与外部工具（如地图、飞书）的标准接口\n"
                    "• cron 表达式：用简单字符表示定时规则的语法，如「0 8 * * *」表示每天早上 8 点执行\n"
                    "• URL：统一资源定位符，即网页地址"
                ),
                "source": "pptx2 第 23-24 张 + YeLuAI PPT 第 56、59 张",
            },
            {
                "title": "工作流与提示词类名词",
                "body": (
                    "• Workflow（工作流）：通过可视化节点编排实现智能体业务流程\n"
                    "• 判断器：工作流中的条件分支节点，根据表达式结果决定流程走向\n"
                    "• 指定回复：工作流节点，当满足特定条件时返回预设的固定回复内容\n"
                    "• 表单收集：引导用户填写表单的节点\n"
                    "• 循环节点：重复执行某段逻辑的节点\n"
                    "• 多模态模型：能够同时处理文本、图像、音频、视频等多种数据类型的 AI 模型\n"
                    "• 输出思考：让模型在最终回答前展示推理过程\n"
                    "• 视觉模型：能够理解和生成图像的多模态大模型\n"
                    "• ASR（语音识别）：将人类语音转换为文本的技术\n"
                    "• TTS（语音合成）：将文本转换为自然语音的技术\n"
                    "• 基础模型：智能体底层使用的大语言模型，决定核心能力上限\n"
                    "• 开场白：用户首次进入对话时智能体自动发送的欢迎语\n"
                    "• 角色设定：为智能体定义的身份、性格与行为准则\n"
                    "• 问题优化：对用户原始问题进行改写或扩展，使其更适合检索或生成"
                ),
                "source": "pptx2 第 5、23 张 + YeLuAI PPT 第 57、58 张",
            },
            {
                "title": "权限与部署类名词",
                "body": (
                    "• 白名单：允许访问智能体或 API 的 IP/用户列表\n"
                    "• 版本恢复：将智能体工作流回滚到历史保存版本的功能\n"
                    "• 私有部署：将 AI 系统部署在企业自有服务器或私有云中，确保数据不出域\n"
                    "• 本地模型部署：部署在私有服务器或本地环境的 AI 模型，保障数据隐私与自主可控\n"
                    "• Cross-modal（跨模态）：在不同数据模态（如图文、音视频）之间进行理解与转换的能力\n"
                    "• Zero-coding（零编码）：通过可视化界面而非编写代码完成开发，降低技术门槛\n"
                    "• 知识库：存放企业私有知识的容器（文档、问答、表格等），AI 从中检索信息\n"
                    "• 回调 URL：外部服务完成处理后向指定地址发送通知的链接"
                ),
                "source": "pptx2 + YeLuAI PPT 第 58、59 张",
            },
        ],
        "no_supplement_note": None,
    },
]
```

---

## Self-Review

**1. Spec coverage:**
- §3 章节映射 → Task 3（CHAPTERS 数据）✅
- §4 抽取规则（保留/丢弃/统一）→ Task 3 已在每条 `body` 中按规则筛选；附录 B 在 Task 4 中说明 ✅
- §5 输出格式（封面/9 章节/附录 A/附录 B/字体）→ Task 2 (封面) + Task 3 (章节) + Task 4 (附录) ✅
- §6 实现方式（python-docx）→ Task 2/3/4 用 `python-docx` ✅
- §8 验收标准 → Task 5 验收脚本 ✅
- §9 后续使用 → Task 6 交付步骤含给 TRAE 的使用说明 ✅

**2. Placeholder scan:** 无 TBD / TODO / "类似 Task N" / "适当错误处理"。所有代码块完整。

**3. Type consistency:**
- `CHAPTERS` 的 dict 字段在 Task 3 Step 1 定义、在 Task 3 Step 2 的 `render_chapter` 中消费，字段名一致（`index` / `title` / `has_supplement` / `supplements` / `no_supplement_note` / `sup.title` / `sup.body` / `sup.source`）。
- `set_cn_font` 函数在 Task 2 Step 1 定义、Task 2/3/4 全部调用，签名一致。
- `OUT` / `EXTRACT_OUT` 路径常量在 Task 2/4 中使用，路径字符串完全一致。

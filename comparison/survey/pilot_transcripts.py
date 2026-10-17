"""Collect the interview transcripts of the simulated pilot from the interviewer agents' logs.

Usage: python3 comparison/survey/pilot_transcripts.py MAP.txt TASKS_DIR OUT_DIR

MAP.txt has one line per interviewee: "<respondent id> <agent id> <entry> <arm>". Each agent's
log (TASKS_DIR/<agent id>.output, JSON lines) holds its replies as SubagentHandback tool calls, in
order: round 1 (questions 1 to 7), round 2 (8 to 12), and any follow-up. Writes
OUT_DIR/transcript-<id>.md with the rounds in order.
"""
import json
import os
import sys


def replies(path):
    out = []
    for line in open(path):
        try:
            rec = json.loads(line)
        except ValueError:
            continue
        if rec.get("type") != "assistant":
            continue
        msg = rec.get("message") or {}
        for block in msg.get("content") or []:
            if block.get("type") == "tool_use" and isinstance(block.get("input"), dict) and "message" in block["input"]:
                out.append(block["input"]["message"])
    return out


def main(map_path, tasks, out):
    os.makedirs(out, exist_ok=True)
    for line in open(map_path):
        rid, aid, entry, arm = line.split()
        rounds = replies(os.path.join(tasks, aid + ".output"))
        titles = ["Round 1 (questions 1 to 7)", "Round 2 (questions 8 to 12)", "Follow-up"]
        body = [f"# Interview transcript: respondent {rid} ({entry}, {arm})", ""]
        for i, r in enumerate(rounds):
            body += [f"## {titles[i] if i < len(titles) else f'Round {i + 1}'}", "", r.strip(), ""]
        with open(os.path.join(out, f"transcript-{rid}.md"), "w") as f:
            f.write("\n".join(body))
        print(rid, len(rounds), "rounds")


if __name__ == "__main__":
    main(*sys.argv[1:4])

# minimal client for the blender-mcp addon socket (same JSON protocol the MCP server uses)
import socket, json, sys
def send(cmd_type, params=None, timeout=600):
    s = socket.create_connection(("localhost", 9876), timeout=timeout)
    s.sendall(json.dumps({"type": cmd_type, "params": params or {}}).encode())
    buf = b""
    while True:
        chunk = s.recv(1 << 20)
        if not chunk: break
        buf += chunk
        try:
            return json.loads(buf.decode())
        except json.JSONDecodeError:
            continue
    return json.loads(buf.decode())
if __name__ == "__main__":
    t = sys.argv[1]
    if t == "code":
        print(json.dumps(send("execute_code", {"code": open(sys.argv[2]).read()}), ensure_ascii=False)[:3000])
    else:
        print(json.dumps(send(t), ensure_ascii=False)[:3000])

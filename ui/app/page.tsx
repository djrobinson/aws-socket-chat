"use client";

import { useCallback, useEffect, useState } from "react";
import useWebSocket, { ReadyState } from "react-use-websocket";

export default function Home() {
  //Public API that will echo messages sent to it back to the client
  const [socketUrl, setSocketUrl] = useState("wss://echo.websocket.org");
  const [messageHistory, setMessageHistory] = useState([]);

  const { sendMessage, lastMessage, readyState } = useWebSocket(socketUrl);

  useEffect(() => {
    if (lastMessage !== null) {
      setMessageHistory((prev) => prev.concat(lastMessage));
    }
  }, [lastMessage, setMessageHistory]);

  const handleClickChangeSocketUrl = useCallback(
    () =>
      setSocketUrl("wss://0af3w0tlla.execute-api.us-west-2.amazonaws.com/dev"),
    []
  );

  const handleClickSendMessage = useCallback(() => sendMessage("Hello"), []);

  const connectionStatus = {
    [ReadyState.CONNECTING]: "Connecting",
    [ReadyState.OPEN]: "Open",
    [ReadyState.CLOSING]: "Closing",
    [ReadyState.CLOSED]: "Closed",
    [ReadyState.UNINSTANTIATED]: "Uninstantiated",
  }[readyState];

  return (
    <div>
      <p>
        <button onClick={handleClickChangeSocketUrl}>
          Click Me to change Socket Url
        </button>
      </p>
      <p>
        <button
          onClick={handleClickSendMessage}
          disabled={readyState !== ReadyState.OPEN}
        >
          Click Me to send Hello
        </button>
      </p>
      <p>The WebSocket is currently {connectionStatus}</p>
      {lastMessage ? <p>Last message: {lastMessage.data}</p> : null}
      <ul>
        {messageHistory.map((message, idx) => (
          <p key={idx}>{message ? message.data : null}</p>
        ))}
      </ul>
    </div>
  );
}

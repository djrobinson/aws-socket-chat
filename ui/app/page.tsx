"use client";

import { useCallback, useEffect, useState } from "react";
import useWebSocket, { ReadyState } from "react-use-websocket";

type Message = {
  user: string;
  data: string;
};

export default function Home() {
  const [messageHistory, setMessageHistory] = useState<Message[]>([]);
  const [currentUserMessage, setCurrentUserMessage] = useState("");

  const { sendMessage, lastMessage, readyState } = useWebSocket(
    "wss://0af3w0tlla.execute-api.us-west-2.amazonaws.com/dev"
  );

  useEffect(() => {
    if (lastMessage !== null) {
      setMessageHistory((prev) => prev.concat(lastMessage));
    }
  }, [lastMessage, setMessageHistory]);

  const handleClickSendMessage = useCallback(() => {
    if (currentUserMessage === "") return;
    const message: Message = { user: "SELF", data: currentUserMessage };
    sendMessage(message.data);
    setMessageHistory((prev) => prev.concat(message));
    setCurrentUserMessage("");
  }, [currentUserMessage, sendMessage, setCurrentUserMessage]);

  const handleKeyDown = useCallback(
    (event: React.KeyboardEvent) => {
      if (event.key === "Enter") {
        handleClickSendMessage();
      }
    },
    [handleClickSendMessage]
  );

  const connectionStatus = {
    [ReadyState.CONNECTING]: "Connecting",
    [ReadyState.OPEN]: "Open",
    [ReadyState.CLOSING]: "Closing",
    [ReadyState.CLOSED]: "Closed",
    [ReadyState.UNINSTANTIATED]: "Uninstantiated",
  }[readyState];

  return (
    <div className="fixed bottom-16 right-4 w-96">
      <div className="bg-white shadow-md rounded-lg max-w-lg w-full">
        <div className="p-4 border-b bg-teal-500 text-white rounded-t-lg flex justify-between items-center">
          <p className="text-lg font-semibold">Admin Bot</p>
          <button
            id="close-chat"
            className="text-gray-300 hover:text-gray-400 focus:outline-none focus:text-gray-400"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="w-6 h-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M6 18L18 6M6 6l12 12"
              ></path>
            </svg>
          </button>
        </div>
        <div id="chatbox" className="p-4 h-80 overflow-y-auto">
          {messageHistory.map((message, index) => (
            <div
              key={index}
              className={`mb-2 ${message.user === "SELF" ? "text-right" : ""}`}
            >
              <p
                className={`${
                  message.user === "SELF"
                    ? "bg-teal-500 text-white rounded-lg py-2 px-4 inline-block"
                    : "bg-gray-200 text-gray-700 rounded-lg py-2 px-4 inline-block"
                }`}
              >
                {message.data}
              </p>
            </div>
          ))}
        </div>
        <div className="p-4 border-t flex">
          <input
            id="user-input"
            value={currentUserMessage}
            onChange={(event) => setCurrentUserMessage(event.target.value)}
            onKeyDown={handleKeyDown}
            type="text"
            placeholder="Type a message"
            className="text-black w-full px-3 py-2 border rounded-l-md focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
          <button
            id="send-button"
            className="bg-teal-500 text-white px-4 py-2 rounded-r-md hover:bg-teal-600 transition duration-300"
            onClick={handleClickSendMessage}
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}

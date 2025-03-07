import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import { MessageCircle, Send, X, Bot, User } from 'lucide-react';
 
const ChatBot = () => {
  const [messages, setMessages] = useState([{ sender: 'bot', text: "Hello! I'm your HealthLink Assistant. How can I help you today?" }]);
  const [inputMessage, setInputMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);
 
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);
 
  useEffect(() => {
    inputRef.current?.focus();
  }, []);
 
  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };
 
  const sendMessage = async () => {
    if (!inputMessage.trim()) return;
 
    const userMessage = inputMessage.trim();
    const newMessages = [...messages, { sender: 'user', text: userMessage }];
    setMessages(newMessages);
    setInputMessage('');
    setIsTyping(true);
 
    try {
      const { data } = await axios.post('http://127.0.0.1:5000/chat', { message: userMessage });
      setIsTyping(false);
      setMessages([...newMessages, { sender: 'bot', text: data.response }]);
    } catch (error) {
      setIsTyping(false);
      setMessages([...newMessages, { sender: 'bot', text: "I'm sorry, I couldn't process your request. Please try again later." }]);
    }
  };
 
  return (
    <>
      <div className="chatbot-header">
        <div className="chatbot-header-title">
          <Bot size={20} />
          <h3>HealthLink Assistant</h3>
        </div>
      </div>
 
      <div className="chatbot-messages">
        {messages.map((msg, index) => (
          <div key={index} className={`chat-message ${msg.sender}`}>
            <div className="message-avatar">
              {msg.sender === 'bot' ? <Bot size={16} /> : <User size={16} />}
            </div>
            <div className="message-content">
              {msg.text}
            </div>
          </div>
        ))}
 
        {isTyping && (
          <div className="chat-message bot">
            <div className="message-avatar">
              <Bot size={16} />
            </div>
            <div className="message-content typing-indicator">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        )}
 
        <div ref={messagesEndRef} />
      </div>
 
      <div className="chatbot-input">
        <input
          ref={inputRef}
          type="text"
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Type your message..."
          disabled={isTyping}
        />
        <button 
          onClick={sendMessage} 
          disabled={!inputMessage.trim() || isTyping}
          className={!inputMessage.trim() || isTyping ? "disabled" : ""}
        >
          <Send size={18} />
        </button>
      </div>
    </>
  );
};
 
export default ChatBot;
 
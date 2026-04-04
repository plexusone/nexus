package protocol

import "time"

// MessageType identifies the type of WebSocket message
type MessageType string

const (
	// Server -> Client
	TypeSessions MessageType = "sessions"
	TypeOutput   MessageType = "output"
	TypePrompt   MessageType = "prompt"
	TypeMenu     MessageType = "menu"
	TypeWizard   MessageType = "wizard"
	TypeStatus   MessageType = "status"
	TypeClear    MessageType = "clear"
	TypeError    MessageType = "error"

	// Client -> Server
	TypeList        MessageType = "list"
	TypeSubscribe   MessageType = "subscribe"
	TypeUnsubscribe MessageType = "unsubscribe"
	TypeInput       MessageType = "input"
	TypeKey         MessageType = "key"
	TypeAction      MessageType = "action"
)

// BaseMessage contains common fields for all messages
type BaseMessage struct {
	Type      MessageType `json:"type"`
	SessionID string      `json:"sessionId,omitempty"`
	Timestamp int64       `json:"timestamp,omitempty"`
}

// SessionInfo represents a tmux session
type SessionInfo struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Status       string `json:"status"`
	LastActivity int64  `json:"lastActivity"`
}

// SessionsMessage is sent when session list changes
type SessionsMessage struct {
	BaseMessage
	Sessions []SessionInfo `json:"sessions"`
}

// OutputMessage contains terminal output
type OutputMessage struct {
	BaseMessage
	Text  string `json:"text"`
	Style string `json:"style,omitempty"` // info, error, success, command
}

// PromptType identifies the kind of prompt
type PromptType string

const (
	PromptYesNo  PromptType = "yes_no"
	PromptInput  PromptType = "input"
	PromptChoice PromptType = "choice"
)

// PromptMessage indicates an interactive prompt was detected
type PromptMessage struct {
	BaseMessage
	PromptType    PromptType `json:"promptType"`
	Title         string     `json:"title,omitempty"`
	Message       string     `json:"message"`
	Options       []string   `json:"options,omitempty"`
	DefaultOption string     `json:"defaultOption,omitempty"`
}

// MenuItem represents an item in a menu
type MenuItem struct {
	Label    string `json:"label"`
	Selected bool   `json:"selected"`
	Index    int    `json:"index"`
}

// MenuMessage indicates a scrollable menu was detected
type MenuMessage struct {
	BaseMessage
	Title        string     `json:"title,omitempty"`
	Items        []MenuItem `json:"items"`
	CurrentIndex int        `json:"currentIndex"`
	MultiSelect  bool       `json:"multiSelect"`
}

// WizardField represents a field in a wizard step
type WizardField struct {
	Name    string   `json:"name"`
	Type    string   `json:"type"` // select, checkbox, input
	Label   string   `json:"label,omitempty"`
	Options []string `json:"options,omitempty"`
	Value   string   `json:"value,omitempty"`
}

// WizardMessage indicates a multi-step wizard was detected
type WizardMessage struct {
	BaseMessage
	Title       string        `json:"title,omitempty"`
	CurrentStep int           `json:"currentStep"`
	TotalSteps  int           `json:"totalSteps"`
	Fields      []WizardField `json:"fields,omitempty"`
	Actions     []string      `json:"actions"` // back, next, submit, cancel
}

// TokenUsage tracks token consumption
type TokenUsage struct {
	Input  int `json:"input"`
	Output int `json:"output"`
}

// StatusMessage indicates session status change
type StatusMessage struct {
	BaseMessage
	Status     string      `json:"status"` // running, idle, stuck, ended
	TokenUsage *TokenUsage `json:"tokenUsage,omitempty"`
}

// ClearMessage indicates terminal buffer should be cleared
type ClearMessage struct {
	BaseMessage
}

// ErrorMessage indicates an error occurred
type ErrorMessage struct {
	BaseMessage
	Error string `json:"error"`
}

// SubscribeMessage requests subscription to sessions
type SubscribeMessage struct {
	BaseMessage
	SessionIDs []string `json:"sessionIds"`
}

// UnsubscribeMessage requests unsubscription from sessions
type UnsubscribeMessage struct {
	BaseMessage
	SessionIDs []string `json:"sessionIds"`
}

// InputMessage sends text input to a session
type InputMessage struct {
	BaseMessage
	Text string `json:"text"`
}

// KeyMessage sends a special key to a session
type KeyMessage struct {
	BaseMessage
	Key string `json:"key"` // enter, tab, escape, up, down, left, right, space, backspace, y, n, a
}

// ActionMessage responds to a prompt/menu/wizard
type ActionMessage struct {
	BaseMessage
	Action string `json:"action"` // select, submit, cancel, back, next
	Value  string `json:"value,omitempty"`
}

// NewBaseMessage creates a new base message with timestamp
func NewBaseMessage(msgType MessageType, sessionID string) BaseMessage {
	return BaseMessage{
		Type:      msgType,
		SessionID: sessionID,
		Timestamp: time.Now().Unix(),
	}
}

// NewOutputMessage creates a new output message
func NewOutputMessage(sessionID, text string) *OutputMessage {
	return &OutputMessage{
		BaseMessage: NewBaseMessage(TypeOutput, sessionID),
		Text:        text,
	}
}

// NewSessionsMessage creates a new sessions message
func NewSessionsMessage(sessions []SessionInfo) *SessionsMessage {
	return &SessionsMessage{
		BaseMessage: NewBaseMessage(TypeSessions, ""),
		Sessions:    sessions,
	}
}

// NewPromptMessage creates a new prompt message
func NewPromptMessage(sessionID string, promptType PromptType, message string, options []string) *PromptMessage {
	return &PromptMessage{
		BaseMessage: NewBaseMessage(TypePrompt, sessionID),
		PromptType:  promptType,
		Message:     message,
		Options:     options,
	}
}

// NewMenuMessage creates a new menu message
func NewMenuMessage(sessionID string, items []MenuItem, currentIndex int, multiSelect bool) *MenuMessage {
	return &MenuMessage{
		BaseMessage:  NewBaseMessage(TypeMenu, sessionID),
		Items:        items,
		CurrentIndex: currentIndex,
		MultiSelect:  multiSelect,
	}
}

// NewStatusMessage creates a new status message
func NewStatusMessage(sessionID, status string) *StatusMessage {
	return &StatusMessage{
		BaseMessage: NewBaseMessage(TypeStatus, sessionID),
		Status:      status,
	}
}

// NewErrorMessage creates a new error message
func NewErrorMessage(sessionID, errMsg string) *ErrorMessage {
	return &ErrorMessage{
		BaseMessage: NewBaseMessage(TypeError, sessionID),
		Error:       errMsg,
	}
}

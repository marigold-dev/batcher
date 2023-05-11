export type NotificationsEnabled = {
  rates: boolean;
  deposits: boolean;
  batch_status: boolean;
};

export type TelegramMessageContents = {
  message: string;
  message_options: any;
};

export enum MessageType {
  BIGMAP = 0,
  OPERATION = 1,
}

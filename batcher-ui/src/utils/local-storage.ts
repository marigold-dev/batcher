const setByKey = (key: string, content?: unknown) => {
  if (!content) return localStorage.removeItem(key);
  const serializedContent = JSON.stringify(content);
  return localStorage.setItem(key, serializedContent);
};

const getByKey = (key: string) => {
  const content = localStorage.getItem(key);

  if (content) {
    return JSON.parse(content);
  }
  return null;
};

export { setByKey, getByKey };

import { /* HubConnection */ HubConnectionBuilder } from '@microsoft/signalr';
import React, { createContext, useEffect } from 'react';
// import { useSelector } from 'react-redux';
import { useDispatch } from 'react-redux';
import { newEvent } from 'src/actions/events';
// import { userAddressSelector } from 'src/reducers';
import { setup /* subscribeTokenBalances */ } from 'utils/webSocketUtils';

export const EventsContext = createContext<{}>({});

export const EventsProvider = ({ children }: { children: React.ReactNode }) => {
  // const [socket, setSocket] = useState<HubConnection | undefined>(undefined);
  const dispatch = useDispatch();
  // const userAddress = useSelector(userAddressSelector);

  useEffect(() => {
    const socket = new HubConnectionBuilder()
      .withUrl(process.env.NEXT_PUBLIC_TZKT_URI_API + '/v1/ws')
      .build();
    setup(socket);
    // setSocket(socket);
    socket.on('bigmaps', e => {
      if (e.data) dispatch(newEvent(e));
    });
  }, [dispatch]);

  // useEffect(() => {
  //   console.warn(socket?.state, userAddress);
  //   subscribeTokenBalances(socket, userAddress);
  // }, [socket, userAddress]);

  return <EventsContext.Provider value={{}}>{children}</EventsContext.Provider>;
};

export const useEvents = () => React.useContext(EventsContext);

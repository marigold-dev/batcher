import { NextComponentType, NextPageContext } from 'next';
import { useEffect, useState } from 'react';
import Footer from './Footer';
import NavBar from './NavBar';
import { batcherSetup, getCurrentBatchNumber } from 'src/actions';
import { useDispatch } from 'react-redux';
import { setByKey } from 'src/utils/local-storage';
import { getStorage } from 'src/utils/utils';
import { useSelector } from 'react-redux';
import { batcherStatusSelector } from 'src/reducers';
import { BatcherStatus } from 'src/types';

interface RootProps {
  Component: NextComponentType<NextPageContext, any, any>;
}

const Root = ({ Component }: RootProps) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const dispatch = useDispatch();
  const status = useSelector(batcherStatusSelector);

  // Override TZKT base url if we are in ghostnet
  useEffect(() => {
    dispatch(getCurrentBatchNumber());
  }, [dispatch]);

  useEffect(() => {
    getStorage().then(({ rates_current, batch_set, user_batch_ordertypes }) => {
      setByKey('rates_current', rates_current);
      setByKey('batches', batch_set.batches);
      setByKey('user_batch_ordertypes', user_batch_ordertypes);
    });
  }, []);

  useEffect(() => {
    if (status === BatcherStatus.OPEN) {
      dispatch(batcherSetup());
    }
  }, [status, dispatch]);

  return (
    <div className="flex flex-col justify-between h-screen">
      <div>
        <NavBar isMenuOpen={isMenuOpen} setIsMenuOpen={setIsMenuOpen} />
        {!isMenuOpen && <Component />}
      </div>
      <Footer />
    </div>
  );
};

export default Root;

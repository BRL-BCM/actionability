
module GenboreeAcUiFullViewHelper
  def self.included(includingClass)
    includingClass.send(:include, KbHelpers::KbProjectHelper)
    includingClass.send(:include, GenboreeAcHelper)
    includingClass.send(:include, GenboreeAcHelper::PermHelper)
    includingClass.send(:include, GenboreeAcAsyncHelper)
  end

  def self.extended(extendingObj)
    extendingObj.send(:extend, KbHelpers::KbProjectHelper)
    extendingObj.send(:extend, GenboreeAcHelper)
    extendingObj.send(:extend, GenboreeAcHelper::PermHelper)
    extendingObj.send(:extend, GenboreeAcAsyncHelper)
  end
end

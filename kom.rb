# -*- coding: iso-8859-1 -*-
#
# Den här filen har kompilerats från kom.py ur python-lyskom.
#
# LysKOM Protocol A version 10/11 client interface for Python
# $Id: kom.py,v 1.40 2004/07/18 19:58:24 astrand Exp $
# (C) 1999-2002 Kent Engström. Released under GPL.

require 'socket'
module Kom
  WHITESPACE = " \t\r\n"
  DIGITS = "01234567890"
  float_chars = DIGITS + "eE.-+"
  ORD_0 = "0"[0]
  MAX_TEXT_SIZE = Integer(2 ** 31 - 1)
  class Error < Exception; end
  class ServerError < Error; end
  class NotImplemented < ServerError; end
  class ObsoleteCall < ServerError; end
  class InvalidPassword < ServerError; end
  class StringTooLong < ServerError; end
  class LoginFirst < ServerError; end
  class LoginDisallowed < ServerError; end
  class ConferenceZero < ServerError; end
  class UndefinedConference < ServerError; end
  class UndefinedPerson < ServerError; end
  class AccessDenied < ServerError; end
  class PermissionDenied < ServerError; end
  class NotMember < ServerError; end
  class NoSuchText < ServerError; end
  class TextZero < ServerError; end
  class NoSuchLocalText < ServerError; end
  class LocalTextZero < ServerError; end
  class BadName < ServerError; end
  class IndexOutOfRange < ServerError; end
  class ConferenceExists < ServerError; end
  class PersonExists < ServerError; end
  class SecretPublic < ServerError; end
  class Letterbox < ServerError; end
  class LdbError < ServerError; end
  class IllegalMisc < ServerError; end
  class IllegalInfoType < ServerError; end
  class AlreadyRecipient < ServerError; end
  class AlreadyComment < ServerError; end
  class AlreadyFootnote < ServerError; end
  class NotRecipient < ServerError; end
  class NotComment < ServerError; end
  class NotFootnote < ServerError; end
  class RecipientLimit < ServerError; end
  class CommentLimit < ServerError; end
  class FootnoteLimit < ServerError; end
  class MarkLimit < ServerError; end
  class NotAuthor < ServerError; end
  class NoConnect < ServerError; end
  class OutOfmemory < ServerError; end
  class ServerIsCrazy < ServerError; end
  class ClientIsCrazy < ServerError; end
  class UndefinedSession < ServerError; end
  class RegexpError < ServerError; end
  class NotMarked < ServerError; end
  class TemporaryFailure < ServerError; end
  class LongArray < ServerError; end
  class AnonymousRejected < ServerError; end
  class IllegalAuxItem < ServerError; end
  class AuxItemPermission < ServerError; end
  class UnknownAsync < ServerError; end
  class InternalError < ServerError; end
  class FeatureDisabled < ServerError; end
  class MessageNotSent < ServerError; end
  class InvalidMembershipType < ServerError; end
  class InvalidRange < ServerError; end
  class InvalidRangeList < ServerError; end
  class UndefinedMeasurement < ServerError; end
  class PriorityDenied < ServerError; end
  class WeightDenied < ServerError; end
  class WeightZero < ServerError; end
  class BadBool < ServerError; end
  ERROR_DICT = {2 => NotImplemented, 3 => ObsoleteCall, 4 => InvalidPassword, 5 => StringTooLong, 6 => LoginFirst, 7 => LoginDisallowed, 8 => ConferenceZero, 9 => UndefinedConference, 10 => UndefinedPerson, 11 => AccessDenied, 12 => PermissionDenied, 13 => NotMember, 14 => NoSuchText, 15 => TextZero, 16 => NoSuchLocalText, 17 => LocalTextZero, 18 => BadName, 19 => IndexOutOfRange, 20 => ConferenceExists, 21 => PersonExists, 22 => SecretPublic, 23 => Letterbox, 24 => LdbError, 25 => IllegalMisc, 26 => IllegalInfoType, 27 => AlreadyRecipient, 28 => AlreadyComment, 29 => AlreadyFootnote, 30 => NotRecipient, 31 => NotComment, 32 => NotFootnote, 33 => RecipientLimit, 34 => CommentLimit, 35 => FootnoteLimit, 36 => MarkLimit, 37 => NotAuthor, 38 => NoConnect, 39 => OutOfmemory, 40 => ServerIsCrazy, 41 => ClientIsCrazy, 42 => UndefinedSession, 43 => RegexpError, 44 => NotMarked, 45 => TemporaryFailure, 46 => LongArray, 47 => AnonymousRejected, 48 => IllegalAuxItem, 49 => AuxItemPermission, 50 => UnknownAsync, 51 => InternalError, 52 => FeatureDisabled, 53 => MessageNotSent, 54 => InvalidMembershipType, 55 => InvalidRange, 56 => InvalidRangeList, 57 => UndefinedMeasurement, 58 => PriorityDenied, 59 => WeightDenied, 60 => WeightZero, 61 => BadBool}
  class LocalError < Error; end
  class BadInitialResponse < LocalError; end
  class BadRequestId < LocalError; end
  class ProtocolError < LocalError; end
  class UnimplementedAsync < LocalError; end
  class ReceiveError < LocalError; end
  MI_RECPT = 0
  MI_CC_RECPT = 1
  MI_COMM_TO = 2
  MI_COMM_IN = 3
  MI_FOOTN_TO = 4
  MI_FOOTN_IN = 5
  MI_LOC_NO = 6
  MI_REC_TIME = 7
  MI_SENT_BY = 8
  MI_SENT_AT = 9
  MI_BCC_RECPT = 15
  MIR_TO = MI_RECPT
  MIR_CC = MI_CC_RECPT
  MIR_BCC = MI_BCC_RECPT
  MIC_COMMENT = MI_COMM_TO
  MIC_FOOTNOTE = MI_FOOTN_TO

  AI_CONTENT_TYPE = 1
  AI_FAST_REPLY = 2
  AI_CROSS_REFERENCE = 3
  AI_NO_COMMENTS = 4
  AI_PERSONAL_COMMENT = 5
  AI_REQUEST_CONFIRMATION = 6
  AI_READ_CONFIRM = 7
  AI_REDIRECT = 8
  AI_X_FACE = 9
  AI_ALTERNATE_NAME = 10
  AI_PGP_SIGNATURE = 11
  AI_PGP_PUBLIC_KEY = 12
  AI_E_MAIL_ADDRESS = 13
  AI_FAQ_TEXT = 14
  AI_CREATING_SOFTWARE = 15
  AI_MX_AUTHOR = 16
  AI_MX_FROM = 17
  AI_MX_REPLY_TO = 18
  AI_MX_TO = 19
  AI_MX_CC = 20
  AI_MX_DATE = 21
  AI_MX_MESSAGE_ID = 22
  AI_MX_IN_REPLY_TO = 23
  AI_MX_MISC = 24
  AI_MX_ALLOW_FILTER = 25
  AI_MX_REJECT_FORWARD = 26
  AI_NOTIFY_COMMENTS = 27
  AI_FAQ_FOR_CONF = 28
  AI_RECOMMENDED_CONF = 29
  AI_ALLOWED_CONTENT_TYPE = 30
  AI_CANONICAL_NAME = 31
  AI_MX_LIST_NAME = 32
  AI_SEND_COMMENTS_TO = 33
  AI_WORLD_READABLE = 34
  AI_MX_REFUSE_IMPORT = 35
  AI_MX_MIME_BELONGS_TO = 10100
  AI_MX_MIME_PART_IN = 10101
  AI_MX_MIME_MISC = 10102
  AI_MX_ENVELOPE_SENDER = 10103
  AI_MX_MIME_FILE_NAME = 10104
  AI_ELISP_CLIENT_READ_FAQ = 10000
  AI_ELISP_CLIENT_REJECTED_RECOMMENDATION = 10001
  aux_item_number_to_name = {AI_CONTENT_TYPE => 'content-type', AI_FAST_REPLY => 'fast-reply', AI_CROSS_REFERENCE => 'cross-reference', AI_NO_COMMENTS => 'no-comments', AI_PERSONAL_COMMENT => 'personal-comment', AI_REQUEST_CONFIRMATION => 'request-confirmation', AI_READ_CONFIRM => 'read-confirm', AI_REDIRECT => 'redirect', AI_X_FACE => 'x-face', AI_ALTERNATE_NAME => 'alternate-name', AI_PGP_SIGNATURE => 'pgp-signature', AI_PGP_PUBLIC_KEY => 'pgp-public-key', AI_E_MAIL_ADDRESS => 'e-mail-address', AI_FAQ_TEXT => 'faq-text', AI_CREATING_SOFTWARE => 'creating-software', AI_MX_AUTHOR => 'mx-author', AI_MX_FROM => 'mx-from', AI_MX_REPLY_TO => 'mx-reply-to', AI_MX_TO => 'mx-to', AI_MX_CC => 'mx-cc', AI_MX_DATE => 'mx-date', AI_MX_MESSAGE_ID => 'mx-message-id', AI_MX_IN_REPLY_TO => 'mx-in-reply-to', AI_MX_MISC => 'mx-misc', AI_MX_ALLOW_FILTER => 'mx-allow-filter', AI_MX_REJECT_FORWARD => 'mx-reject-forward', AI_NOTIFY_COMMENTS => 'notify-comments', AI_FAQ_FOR_CONF => 'faq-for-conf', AI_RECOMMENDED_CONF => 'recommended-conf', AI_ALLOWED_CONTENT_TYPE => 'allowed-content-type', AI_CANONICAL_NAME => 'canonical-name', AI_MX_LIST_NAME => 'mx-list-name', AI_SEND_COMMENTS_TO => 'send-comments-to', AI_WORLD_READABLE => 'world-readable', AI_MX_REFUSE_IMPORT => 'mx-refuse-import', AI_MX_MIME_BELONGS_TO => 'mx-mime-belongs-to', AI_MX_MIME_PART_IN => 'mx-mime-part-in', AI_MX_MIME_MISC => 'mx-mime-misc', AI_MX_ENVELOPE_SENDER => 'mx-envelope-sender', AI_MX_MIME_FILE_NAME => 'mx-mime-file-name', AI_ELISP_CLIENT_READ_FAQ => 'elisp-client-read-faq', AI_ELISP_CLIENT_REJECTED_RECOMMENDATION => 'elisp-client-rejected-recommendation'}

  class Request
    attr_accessor :id, :c
    def register(c)
      @id = c.register_request(self)
      @c = c
    end
    def response
      return @c.wait_and_dequeue(@id)
    end
    def parse_response
      return nil
    end
    def callback(obj, method)
      @callback_obj = obj
      @callback_method = method
      return @id
    end
    def invoke_callback
      if @callback_obj
        @callback_obj.send(@callback_method, self)
      end
    end
    def request_id
      @id
    end
  end
  class ReqLogout < Request
    def initialize(c)
      register(c)
      c.send_string("%d 1\n" % @id)
    end
  end
  class ReqChangeConference < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 2 %d\n" % [@id, conf_no])
    end
  end
  class ReqChangeName < Request
    def initialize(c, conf_no, new_name)
      register(c)
      c.send_string("%d 3 %d %dH%s\n" % [@id, conf_no, new_name.length, new_name])
    end
  end
  class ReqChangeWhatIAmDoing < Request
    def initialize(c, what)
      register(c)
      c.send_string("%d 4 %dH%s\n" % [@id, what.length, what])
    end
  end
  class ReqSetPrivBits < Request
    def initialize(c, person_no, privileges)
      register(c)
      c.send_string("%d 7 %d %s\n" % [@id, person_no, privileges.to_string()])
    end
  end
  class ReqSetPasswd < Request
    def initialize(c, person_no, old_pwd, new_pwd)
      register(c)
      c.send_string("%d 8 %d %dH%s %dH%s\n" % [@id, person_no, old_pwd.length, old_pwd, new_pwd.length, new_pwd])
    end
  end
  class ReqDeleteConf < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 11 %d\n" % [@id, conf_no])
    end
  end
  class ReqSubMember < Request
    def initialize(c, conf_no, person_no)
      register(c)
      c.send_string("%d 15 %d %d\n" % [@id, conf_no, person_no])
    end
  end
  class ReqSetPresentation < Request
    def initialize(c, conf_no, text_no)
      register(c)
      c.send_string("%d 16 %d %d\n" % [@id, conf_no, text_no])
    end
  end
  class ReqSetEtcMoTD < Request
    def initialize(c, conf_no, text_no)
      register(c)
      c.send_string("%d 17 %d %d\n" % [@id, conf_no, text_no])
    end
  end
  class ReqSetSupervisor < Request
    def initialize(c, conf_no, admin)
      register(c)
      c.send_string("%d 18 %d %d\n" % [@id, conf_no, admin])
    end
  end
  class ReqSetPermittedSubmitters < Request
    def initialize(c, conf_no, perm_sub)
      register(c)
      c.send_string("%d 19 %d %d\n" % [@id, conf_no, perm_sub])
    end
  end
  class ReqSetSuperConf < Request
    def initialize(c, conf_no, super_conf)
      register(c)
      c.send_string("%d 20 %d %d\n" % [@id, conf_no, super_conf])
    end
  end
  class ReqSetConfType < Request
    def initialize(c, conf_no, type)
      register(c)
      c.send_string("%d 21 %d %s\n" % [@id, conf_no, type.to_string()])
    end
  end
  class ReqSetGarbNice < Request
    def initialize(c, conf_no, nice)
      register(c)
      c.send_string("%d 22 %d %d\n" % [@id, conf_no, nice])
    end
  end
  class ReqGetMarks < Request
    def initialize(c)
      register(c)
      c.send_string("%d 23\n" % @id)
    end
    def parse_response
      return @c.parse_array(Mark)
    end
  end
  class ReqGetText < Request
    def initialize(c, text_no, start_char = 0, end_char = MAX_TEXT_SIZE)
      register(c)
      c.send_string("%d 25 %d %d %d\n" % [@id, text_no, start_char, end_char])
    end
    def parse_response
      return @c.parse_string()
    end
  end
  class ReqMarkAsRead < Request
    def initialize(c, conf_no, texts)
      register(c)
      c.send_string("%d 27 %d %s\n" % [@id, conf_no, c.array_of_int_to_string(texts)])
    end
  end
  class ReqDeleteText < Request
    def initialize(c, text_no)
      register(c)
      c.send_string("%d 29 %d\n" % [@id, text_no])
    end
  end
  class ReqAddRecipient < Request
    def initialize(c, text_no, conf_no, recpt_type = MIR_TO)
      register(c)
      c.send_string("%d 30 %d %d %d\n" % [@id, text_no, conf_no, recpt_type])
    end
  end
  class ReqSubRecipient < Request
    def initialize(c, text_no, conf_no)
      register(c)
      c.send_string("%d 31 %d %d\n" % [@id, text_no, conf_no])
    end
  end
  class ReqAddComment < Request
    def initialize(c, text_no, comment_to)
      register(c)
      c.send_string("%d 32 %d %d\n" % [@id, text_no, comment_to])
    end
  end
  class ReqSubComment < Request
    def initialize(c, text_no, comment_to)
      register(c)
      c.send_string("%d 33 %d %d\n" % [@id, text_no, comment_to])
    end
  end
  class ReqGetMap < Request
    def initialize(c, conf_no, first_local_no, no_of_texts)
      register(c)
      c.send_string("%d 34 %d %d %d\n" % [@id, conf_no, first_local_no, no_of_texts])
    end
    def parse_response
      return @c.parse_object(TextList)
    end
  end
  class ReqGetTime < Request
    def initialize(c)
      register(c)
      c.send_string("%d 35\n" % @id)
    end
    def parse_response
      return @c.parse_object(Time)
    end
  end
  class ReqAddFootnote < Request
    def initialize(c, text_no, footnote_to)
      register(c)
      c.send_string("%d 37 %d %d\n" % [@id, text_no, footnote_to])
    end
  end
  class ReqSubFootnote < Request
    def initialize(c, text_no, footnote_to)
      register(c)
      c.send_string("%d 38 %d %d\n" % [@id, text_no, footnote_to])
    end
  end
  class ReqSetUnread < Request
    def initialize(c, conf_no, no_of_unread)
      register(c)
      c.send_string("%d 40 %d %d\n" % [@id, conf_no, no_of_unread])
    end
  end
  class ReqSetMoTDOfLysKOM < Request
    def initialize(c, text_no)
      register(c)
      c.send_string("%d 41 %d\n" % [@id, text_no])
    end
  end
  class ReqEnable < Request
    def initialize(c, level)
      register(c)
      c.send_string("%d 42 %d\n" % [@id, level])
    end
  end
  class ReqSyncKOM < Request
    def initialize(c)
      register(c)
      c.send_string("%d 43\n" % @id)
    end
  end
  class ReqShutdownKOM < Request
    def initialize(c, exit_val)
      register(c)
      c.send_string("%d 44 %d\n" % [@id, exit_val])
    end
  end
  class ReqGetPersonStat < Request
    def initialize(c, person_no)
      register(c)
      c.send_string("%d 49 %d\n" % [@id, person_no])
    end
    def parse_response
      return @c.parse_object(Person)
    end
  end
  class ReqGetUnreadConfs < Request
    def initialize(c, person_no)
      register(c)
      c.send_string("%d 52 %d\n" % [@id, person_no])
    end
    def parse_response
      return @c.parse_array_of_int()
    end
  end
  class ReqSendMessage < Request
    def initialize(c, conf_no, message)
      register(c)
      c.send_string("%d 53 %d %dH%s\n" % [@id, conf_no, message.length, message])
    end
  end
  class ReqDisconnect < Request
    def initialize(c, session_no)
      register(c)
      c.send_string("%d 55 %d\n" % [@id, session_no])
    end
  end
  class ReqWhoAmI < Request
    def initialize(c)
      register(c)
      c.send_string("%d 56\n" % @id)
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqSetUserArea < Request
    def initialize(c, person_no, user_area)
      register(c)
      c.send_string("%d 57 %d %d\n" % [@id, person_no, user_area])
    end
  end
  class ReqGetLastText < Request
    def initialize(c, before)
      register(c)
      c.send_string("%d 58 %s\n" % [@id, before.to_string()])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqFindNextTextNo < Request
    def initialize(c, start)
      register(c)
      c.send_string("%d 60 %d\n" % [@id, start])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqFindPreviousTextNo < Request
    def initialize(c, start)
      register(c)
      c.send_string("%d 61 %d\n" % [@id, start])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqLogin < Request
    def initialize(c, person_no, password, invisible = 1)
      register(c)
      c.send_string("%d 62 %d %dH%s %d\n" % [@id, person_no, password.length, password, invisible])
    end
  end
  class ReqSetClientVersion < Request
    def initialize(c, client_name, client_version)
      register(c)
      c.send_string("%d 69 %dH%s %dH%s\n" % [@id, client_name.length, client_name, client_version.length, client_version])
    end
  end
  class ReqGetClientName < Request
    def initialize(c, session_no)
      register(c)
      c.send_string("%d 70 %d\n" % [@id, session_no])
    end
    def parse_response
      return @c.parse_string()
    end
  end
  class ReqGetClientVersion < Request
    def initialize(c, session_no)
      register(c)
      c.send_string("%d 71 %d\n" % [@id, session_no])
    end
    def parse_response
      return @c.parse_string()
    end
  end
  class ReqMarkText < Request
    def initialize(c, text_no, mark_type)
      register(c)
      c.send_string("%d 72 %d %d\n" % [@id, text_no, mark_type])
    end
  end
  class ReqUnmarkText < Request
    def initialize(c, text_no)
      register(c)
      c.send_string("%d 73 %d\n" % [@id, text_no])
    end
  end
  class ReqReZLookup < Request
    def initialize(c, regexp, want_pers = 0, want_confs = 0)
      register(c)
      c.send_string("%d 74 %dH%s %d %d\n" % [@id, regexp.length, regexp, want_pers, want_confs])
    end
    def parse_response
      return @c.parse_array(ConfZInfo)
    end
  end
  class ReqGetVersionInfo < Request
    def initialize(c)
      register(c)
      c.send_string("%d 75\n" % @id)
    end
    def parse_response
      return @c.parse_object(VersionInfo)
    end
  end
  class ReqLookupZName < Request
    def initialize(c, name, want_pers = 0, want_confs = 0)
      register(c)
      c.send_string("%d 76 %dH%s %d %d\n" % [@id, name.length, name, want_pers, want_confs])
    end
    def parse_response
      return @c.parse_array(ConfZInfo)
    end
  end
  class ReqSetLastRead < Request
    def initialize(c, conf_no, last_read)
      register(c)
      c.send_string("%d 77 %d %d\n" % [@id, conf_no, last_read])
    end
  end
  class ReqGetUconfStat < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 78 %d\n" % [@id, conf_no])
    end
    def parse_response
      return @c.parse_object(UConference)
    end
  end
  class ReqSetInfo < Request
    def initialize(c, info)
      register(c)
      c.send_string("%d 79 %s\n" % [@id, info.to_string()])
    end
  end
  class ReqAcceptAsync < Request
    def initialize(c, request_list)
      register(c)
      c.send_string("%d 80 %s\n" % [@id, c.array_of_int_to_string(request_list)])
    end
  end
  class ReqQueryAsync < Request
    def initialize(c)
      register(c)
      c.send_string("%d 81\n" % @id)
    end
    def parse_response
      return @c.parse_array_of_int()
    end
  end
  class ReqUserActive < Request
    def initialize(c)
      register(c)
      c.send_string("%d 82\n" % @id)
    end
  end
  class ReqWhoIsOnDynamic < Request
    def initialize(c, want_visible = 1, want_invisible = 0, active_last = 0)
      register(c)
      c.send_string("%d 83 %d %d %d\n" % [@id, want_visible, want_invisible, active_last])
    end
    def parse_response
      return @c.parse_array(DynamicSessionInfo)
    end
  end
  class ReqGetStaticSessionInfo < Request
    def initialize(c, session_no)
      register(c)
      c.send_string("%d 84 %d\n" % [@id, session_no])
    end
    def parse_response
      return @c.parse_object(StaticSessionInfo)
    end
  end
  class ReqGetCollateTable < Request
    def initialize(c)
      register(c)
      c.send_string("%d 85\n" % @id)
    end
    def parse_response
      return @c.parse_string()
    end
  end
  class ReqCreateText < Request
    def initialize(c, text, misc_info, aux_items = [])
      register(c)
      c.send_string("%d 86 %dH%s %s %s\n" % [@id, text.length, text, misc_info.to_string(), c.array_to_string(aux_items)])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqCreateAnonymousText < Request
    def initialize(c, text, misc_info, aux_items = [])
      register(c)
      c.send_string("%d 87 %dH%s %s %s\n" % [@id, text.length, text, misc_info.to_string(), c.array_to_string(aux_items)])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqCreateConf < Request
    def initialize(c, name, type, aux_items = [])
      register(c)
      c.send_string("%d 88 %dH%s %s %s\n" % [@id, name.length, name, type.to_string(), c.array_to_string(aux_items)])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqCreatePerson < Request
    def initialize(c, name, passwd, flags, aux_items = [])
      register(c)
      c.send_string("%d 89 %dH%s %dH%s %s %s\n" % [@id, name.length, name, passwd.length, passwd, flags.to_string(), c.array_to_string(aux_items)])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqGetTextStat < Request
    def initialize(c, text_no)
      register(c)
      c.send_string("%d 90 %d\n" % [@id, text_no])
    end
    def parse_response
      return @c.parse_object(TextStat)
    end
  end
  class ReqGetConfStat < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 91 %d\n" % [@id, conf_no])
    end
    def parse_response
      return @c.parse_object(Conference)
    end
  end
  class ReqModifyTextInfo < Request
    def initialize(c, text_no, delete, add)
      register(c)
      c.send_string("%d 92 %d %s %s\n" % [@id, text_no, c.array_of_int_to_string(delete), c.array_to_string(add)])
    end
  end
  class ReqModifyConfInfo < Request
    def initialize(c, conf_no, delete, add)
      register(c)
      c.send_string("%d 93 %d %s %s\n" % [@id, conf_no, c.array_of_int_to_string(delete), c.array_to_string(add)])
    end
  end
  class ReqGetInfo < Request
    def initialize(c)
      register(c)
      c.send_string("%d 94\n" % @id)
    end
    def parse_response
      return @c.parse_object(Info)
    end
  end
  class ReqModifySystemInfo < Request
    def initialize(c, delete, add)
      register(c)
      c.send_string("%d 95 %s %s\n" % [@id, c.array_of_int_to_string(delete), c.array_to_string(add)])
    end
  end
  class ReqQueryPredefinedAuxItems < Request
    def initialize(c)
      register(c)
      c.send_string("%d 96\n" % @id)
    end
    def parse_response
      return @c.parse_array_of_int()
    end
  end
  class ReqSetExpire < Request
    def initialize(c, conf_no, expire)
      register(c)
      c.send_string("%d 97 %d %d\n" % [@id, conf_no, expire])
    end
  end
  class ReqQueryReadTexts10 < Request
    def initialize(c, person_no, conf_no)
      register(c)
      c.send_string("%d 98 %d %d\n" % [@id, person_no, conf_no])
    end
    def parse_response
      return @c.parse_object(Membership10)
    end
  end
  ReqQueryReadTexts = ReqQueryReadTexts10
  class ReqGetMembership10 < Request
    def initialize(c, person_no, first, no_of_confs, want_read_texts)
      register(c)
      c.send_string("%d 99 %d %d %d %d\n" % [@id, person_no, first, no_of_confs, want_read_texts])
    end
    def parse_response
      return @c.parse_array(Membership10)
    end
  end
  ReqGetMembership = ReqGetMembership10
  class ReqAddMember < Request
    def initialize(c, conf_no, person_no, priority, where, type)
      register(c)
      c.send_string("%d 100 %d %d %d %d %s\n" % [@id, conf_no, person_no, priority, where, type.to_string()])
    end
  end
  class ReqGetMembers < Request
    def initialize(c, conf_no, first, no_of_members)
      register(c)
      c.send_string("%d 101 %d %d %d\n" % [@id, conf_no, first, no_of_members])
    end
    def parse_response
      return @c.parse_array(Member)
    end
  end
  class ReqSetMembershipType < Request
    def initialize(c, person_no, conf_no, type)
      register(c)
      c.send_string("%d 102 %d %d %s\n" % [@id, person_no, conf_no, type.to_string()])
    end
  end
  class ReqLocalToGlobal < Request
    def initialize(c, conf_no, first_local_no, no_of_existing_texts)
      register(c)
      c.send_string("%d 103 %d %d %d\n" % [@id, conf_no, first_local_no, no_of_existing_texts])
    end
    def parse_response
      return @c.parse_object(TextMapping)
    end
  end
  class ReqMapCreatedTexts < Request
    def initialize(c, author, first_local_no, no_of_existing_texts)
      register(c)
      c.send_string("%d 104 %d %d %d\n" % [@id, author, first_local_no, no_of_existing_texts])
    end
    def parse_response
      return @c.parse_object(TextMapping)
    end
  end
  class ReqSetKeepCommented < Request
    def initialize(c, conf_no, keep_commented)
      register(c)
      c.send_string("%d 105 %d %d\n" % [@id, conf_no, keep_commented])
    end
  end
  class ReqSetPersFlags < Request
    def initialize(c, person_no, flags)
      register(c)
      c.send_string("%d 106 %d %s\n" % [@id, person_no, flags.to_string()])
    end
  end
  class ReqQueryReadTexts11 < Request
    def initialize(c, person_no, conf_no, want_read_ranges, max_ranges)
      register(c)
      c.send_string("%d 107 %d %d %d %d\n" % [@id, person_no, conf_no, want_read_ranges, max_ranges])
    end
    def parse_response
      return @c.parse_object(Membership11)
    end
  end
  class ReqGetMembership11 < Request
    def initialize(c, person_no, first, no_of_confs, want_read_ranges, max_ranges)
      register(c)
      c.send_string("%d 108 %d %d %d %d %d\n" % [@id, person_no, first, no_of_confs, want_read_ranges, max_ranges])
    end
    def parse_response
      return @c.parse_array(Membership11)
    end
  end
  class ReqMarkAsUnread < Request
    def initialize(c, conf_no, text_no)
      register(c)
      c.send_string("%d 109 %d %d\n" % [@id, conf_no, text_no])
    end
  end
  class ReqSetReadRanges < Request
    def initialize(c, conf_no, read_ranges)
      register(c)
      c.send_string("%d 110 %s %s\n" % [@id, conf_no, c.array_to_string(read_ranges)])
    end
  end
  class ReqGetStatsDescription < Request
    def initialize(c)
      register(c)
      c.send_string("%d 111 \n" % @id)
    end
    def parse_response
      return @c.parse_object(StatsDescription)
    end
  end
  class ReqGetStats < Request
    def initialize(c, what)
      register(c)
      c.send_string("%d 112 %dH%s\n" % [@id, what.length, what])
    end
    def parse_response
      return @c.parse_array(Stats)
    end
  end
  class ReqGetBoottimeInfo < Request
    def initialize(c)
      register(c)
      c.send_string("%d 113 \n" % @id)
    end
    def parse_response
      return @c.parse_object(StaticServerInfo)
    end
  end
  class ReqFirstUnusedConfNo < Request
    def initialize(c)
      register(c)
      c.send_string("%d 114\n" % @id)
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqFirstUnusedTextNo < Request
    def initialize(c)
      register(c)
      c.send_string("%d 115\n" % @id)
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqFindNextConfNo < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 116 %d\n" % [@id, conf_no])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqFindPreviousConfNo < Request
    def initialize(c, conf_no)
      register(c)
      c.send_string("%d 117 %d\n" % [@id, conf_no])
    end
    def parse_response
      return @c.parse_int()
    end
  end
  class ReqGetScheduling < Request
    def initialize(c, session_no)
      register(c)
      c.send_string("%d 118 %d\n" % [@id, session_no])
    end
    def parse_response
      return @c.parse_object(SchedulingInfo)
    end
  end
  class ReqSetScheduling < Request
    def initialize(c, session_no, priority, weight)
      register(c)
      c.send_string("%d 119 %d %d %d\n" % [@id, session_no, priority, weight])
    end
  end
  class ReqSetConnectionTimeFormat < Request
    def initialize(c, use_utc)
      register(c)
      c.send_string("%d 120 %d\n" % [@id, use_utc])
    end
  end
  class ReqLocalToGlobalReverse < Request
    def initialize(c, conf_no, local_no_ceiling, no_of_existing_texts)
      register(c)
      c.send_string("%d 121 %d %d %d\n" % [@id, conf_no, local_no_ceiling, no_of_existing_texts])
    end
    def parse_response
      return @c.parse_object(TextMapping)
    end
  end
  class ReqMapCreatedTextsReverse < Request
    def initialize(c, author, local_no_ceiling, no_of_existing_texts)
      register(c)
      c.send_string("%d 122 %d %d %d\n" % [@id, author, local_no_ceiling, no_of_existing_texts])
    end
    def parse_response
      return @c.parse_object(TextMapping)
    end
  end
  class AsyncMessage; end
  ASYNC_NEW_TEXT_OLD = 0
  class AsyncNewTextOld < AsyncMessage
    attr_accessor :text_no, :text_stat
    def parse(c)
      @text_no = c.parse_int()
      @text_stat = c.parse_old_object(TextStat)
    end
  end
  ASYNC_NEW_NAME = 5
  class AsyncNewName < AsyncMessage
    attr_accessor :conf_no, :old_name, :new_name
    def parse(c)
      @conf_no = c.parse_int()
      @old_name = c.parse_string()
      @new_name = c.parse_string()
    end
  end
  ASYNC_I_AM_ON = 6
  class AsyncIAmOn < AsyncMessage
    attr_accessor :info
    def parse(c)
      @info = c.parse_object(WhoInfo)
    end
  end
  ASYNC_SYNC_DB = 7
  class AsyncSyncDB < AsyncMessage
    def parse(c)
    end
  end
  ASYNC_LEAVE_CONF = 8
  class AsyncLeaveConf < AsyncMessage
    attr_accessor :conf_no
    def parse(c)
      @conf_no = c.parse_int()
    end
  end
  ASYNC_LOGIN = 9
  class AsyncLogin < AsyncMessage
    attr_accessor :person_no, :session_no
    def parse(c)
      @person_no = c.parse_int()
      @session_no = c.parse_int()
    end
  end
  ASYNC_REJECTED_CONNECTION = 11
  class AsyncRejectedConnection < AsyncMessage
    def parse(c)
    end
  end
  ASYNC_SEND_MESSAGE = 12
  class AsyncSendMessage < AsyncMessage
    attr_accessor :recipient, :sender, :message
    def parse(c)
      @recipient = c.parse_int()
      @sender = c.parse_int()
      @message = c.parse_string()
    end
  end
  ASYNC_LOGOUT = 13
  class AsyncLogout < AsyncMessage
    attr_accessor :person_no, :session_no
    def parse(c)
      @person_no = c.parse_int()
      @session_no = c.parse_int()
    end
  end
  ASYNC_DELETED_TEXT = 14
  class AsyncDeletedText < AsyncMessage
    attr_accessor :text_no, :text_stat
    def parse(c)
      @text_no = c.parse_int()
      @text_stat = c.parse_object(TextStat)
    end
  end
  ASYNC_NEW_TEXT = 15
  class AsyncNewText < AsyncMessage
    attr_accessor :text_no, :text_stat
    def parse(c)
      @text_no = c.parse_int()
      @text_stat = c.parse_object(TextStat)
    end
  end
  ASYNC_NEW_RECIPIENT = 16
  class AsyncNewRecipient < AsyncMessage
    attr_accessor :text_no, :conf_no, :type
    def parse(c)
      @text_no = c.parse_int()
      @conf_no = c.parse_int()
      @type = c.parse_int()
    end
  end
  ASYNC_SUB_RECIPIENT = 17
  class AsyncSubRecipient < AsyncMessage
    attr_accessor :text_no, :conf_no, :type
    def parse(c)
      @text_no = c.parse_int()
      @conf_no = c.parse_int()
      @type = c.parse_int()
    end
  end
  ASYNC_NEW_MEMBERSHIP = 18
  class AsyncNewMembership < AsyncMessage
    attr_accessor :person_no, :conf_no
    def parse(c)
      @person_no = c.parse_int()
      @conf_no = c.parse_int()
    end
  end
  ASYNC_NEW_USER_AREA = 19
  class AsyncNewUserArea < AsyncMessage
    attr_accessor :person_no, :old_user_area, :new_user_area
    def parse(c)
      @person_no = c.parse_int()
      @old_user_area = c.parse_int()
      @new_user_area = c.parse_int()
    end
  end
  ASYNC_NEW_PRESENTATION = 20
  class AsyncNewPresentation < AsyncMessage
    attr_accessor :conf_no, :old_presentation, :new_presentation
    def parse(c)
      @conf_no = c.parse_int()
      @old_presentation = c.parse_int()
      @new_presentation = c.parse_int()
    end
  end
  ASYNC_NEW_MOTD = 21
  class AsyncNewMotd < AsyncMessage
    attr_accessor :conf_no, :old_motd, :new_motd
    def parse(c)
      @conf_no = c.parse_int()
      @old_motd = c.parse_int()
      @new_motd = c.parse_int()
    end
  end
  ASYNC_TEXT_AUX_CHANGED = 22
  class AsyncTextAuxChanged < AsyncMessage
    attr_accessor :text_no, :deleted, :added
    def parse(c)
      @text_no = c.parse_int()
      @deleted = c.parse_array(AuxItem)
      @added = c.parse_array(AuxItem)
    end
  end
  ASYNC_DICT = {ASYNC_NEW_TEXT_OLD => AsyncNewTextOld, ASYNC_NEW_NAME => AsyncNewName, ASYNC_I_AM_ON => AsyncIAmOn, ASYNC_SYNC_DB => AsyncSyncDB, ASYNC_LEAVE_CONF => AsyncLeaveConf, ASYNC_LOGIN => AsyncLogin, ASYNC_REJECTED_CONNECTION => AsyncRejectedConnection, ASYNC_SEND_MESSAGE => AsyncSendMessage, ASYNC_LOGOUT => AsyncLogout, ASYNC_DELETED_TEXT => AsyncDeletedText, ASYNC_NEW_TEXT => AsyncNewText, ASYNC_NEW_RECIPIENT => AsyncNewRecipient, ASYNC_SUB_RECIPIENT => AsyncSubRecipient, ASYNC_NEW_MEMBERSHIP => AsyncNewMembership, ASYNC_NEW_USER_AREA => AsyncNewUserArea, ASYNC_NEW_PRESENTATION => AsyncNewPresentation, ASYNC_NEW_MOTD => AsyncNewMotd, ASYNC_TEXT_AUX_CHANGED => AsyncTextAuxChanged}
  class Time
    attr_accessor :seconds, :minutes, :hours, :day, :month, :year, :day_of_week, :day_of_year, :is_dst
    def initialize(ptime = nil)
      if ptime == nil
        @seconds = 0
        @minutes = 0
        @hours = 0
        @day = 0
        @month = 0
        @year = 0
        @day_of_week = 0
        @day_of_year = 0
        @is_dst = 0
      else
        dy, dm, dd, th, tm, ts, wd, yd, dt = time.localtime(ptime)
        @seconds = ts
        @minutes = tm
        @hours = th
        @day = dd
        @month = dm - 1
        @year = dy - 1900
        @day_of_week = wd + 1 % 7
        @day_of_year = yd - 1
        @is_dst = dt
      end
    end
    def parse(c)
      @seconds = c.parse_int()
      @minutes = c.parse_int()
      @hours = c.parse_int()
      @day = c.parse_int()
      @month = c.parse_int()
      @year = c.parse_int()
      @day_of_week = c.parse_int()
      @day_of_year = c.parse_int()
      @is_dst = c.parse_int()
    end
    def to_string
      return "%d %d %d %d %d %d %d %d %d" % [@seconds, @minutes, @hours, @day, @month, @year, @day_of_week, @day_of_year, @is_dst]
    end
    def to_python_time
      return time.mktime([@year + 1900, @month + 1, @day, @hours, @minutes, @seconds, @day_of_week - 1 % 7, @day_of_year + 1, @is_dst])
    end
    def to_date_and_time
      return "%04d-%02d-%02d %02d:%02d:%02d" % [@year + 1900, @month + 1, @day, @hours, @minutes, @seconds]
    end
    def inspect
      return "<Time %s>" % to_date_and_time()
    end
  end
  class ConfZInfo
    attr_accessor :name, :type, :conf_no
    def parse(c)
      @name = c.parse_string()
      @type = c.parse_old_object(ConfType)
      @conf_no = c.parse_int()
    end
    def inspect
      return "<ConfZInfo %d: %s>" % [@conf_no, @name]
    end
  end
  class RawMiscInfo
    attr_accessor :type
    def parse(c)
      @type = c.parse_int()
      if [MI_REC_TIME, MI_SENT_AT].include?(@type)
        @data = c.parse_object(Time)
      else
        @data = c.parse_int()
      end
    end
    def inspect
      return "<MiscInfo %d: %s>" % [@type, @data]
    end
  end
  class MIRecipient
    attr_accessor :type, :recpt, :loc_no, :rec_time, :sent_by, :sent_at
    def initialize(type = MIR_TO, recpt = 0)
      @type = type
      @recpt = recpt
      @loc_no = nil
      @rec_time = nil
      @sent_by = nil
      @sent_at = nil
    end
    def decode_additional(raw, i)
      while i < raw.length
        if raw[i].type == MI_LOC_NO
          @loc_no = raw[i].data
        elsif raw[i].type == MI_REC_TIME
          @rec_time = raw[i].data
        elsif raw[i].type == MI_SENT_BY
          @sent_by = raw[i].data
        elsif raw[i].type == MI_SENT_AT
          @sent_at = raw[i].data
        else
          return i
        end
        i = i + 1
      end
      return i
    end
    def get_tuples
      return [[@type, @recpt]]
    end
  end
  class MICommentTo
    attr_accessor :type, :text_no, :sent_by, :sent_at
    def initialize(type = MIC_COMMENT, text_no = 0)
      @type = type
      @text_no = text_no
      @sent_by = nil
      @sent_at = nil
    end
    def decode_additional(raw, i)
      while i < raw.length
        if raw[i].type == MI_SENT_BY
          @sent_by = raw[i].data
        elsif raw[i].type == MI_SENT_AT
          @sent_at = raw[i].data
        else
          return i
        end
        i = i + 1
      end
      return i
    end
    def get_tuples
      return [[@type, @text_no]]
    end
  end
  class MICommentIn
    attr_accessor :type, :text_no
    def initialize(type = MIC_COMMENT, text_no = 0)
      @type = type
      @text_no = text_no
    end
    def get_tuples
      return []
    end
  end
  class CookedMiscInfo
    attr_accessor :recipient_list, :comment_to_list, :comment_in_list
    def initialize
      @recipient_list = []
      @comment_to_list = []
      @comment_in_list = []
    end
    def parse(c)
      raw = c.parse_array(RawMiscInfo)
      i = 0
      while i < raw.length
        if [MI_RECPT, MI_CC_RECPT, MI_BCC_RECPT].include?(raw[i].type)
          r = MIRecipient.new(raw[i].type, raw[i].data)
          i = r.decode_additional(raw, i + 1)
          @recipient_list.push(r)
        elsif [MI_COMM_TO, MI_FOOTN_TO].include?(raw[i].type)
          ct = MICommentTo.new(raw[i].type, raw[i].data)
          i = ct.decode_additional(raw, i + 1)
          @comment_to_list.push(ct)
        elsif [MI_COMM_IN, MI_FOOTN_IN].include?(raw[i].type)
          ci = MICommentIn.new(raw[i].type - 1, raw[i].data)
          i = i + 1
          @comment_in_list.push(ci)
        else
          raise ProtocolError
        end
      end
    end
    def to_string
      list = []
      for r in @comment_to_list + @recipient_list + @comment_in_list
        list = list + r.get_tuples()
      end
      return "%d { %s}" % [list.length, list.map { |x| "%d %d " % [x[0], x[1]] }.join("")]
    end
  end
  class AuxItemFlags
    attr_accessor :deleted, :inherit, :secret, :hide_creator, :dont_garb, :reserved2, :reserved3, :reserved4, :deleted, :inherit, :secret, :hide_creator, :dont_garb, :reserved2, :reserved3, :reserved4
    def initialize
      @deleted = 0
      @inherit = 0
      @secret = 0
      @hide_creator = 0
      @dont_garb = 0
      @reserved2 = 0
      @reserved3 = 0
      @reserved4 = 0
    end
    def parse(c)
      @deleted, @inherit, @secret, @hide_creator, @dont_garb, @reserved2, @reserved3, @reserved4 = c.parse_bitstring(8)
    end
    def to_string
      return "%d%d%d%d%d%d%d%d" % [@deleted, @inherit, @secret, @hide_creator, @dont_garb, @reserved2, @reserved3, @reserved4]
    end
  end
  class AuxItem
    attr_accessor :aux_no, :tag, :creator, :created_at, :flags, :inherit_limit, :data, :aux_no, :tag, :creator, :created_at, :flags, :inherit_limit, :data
    def initialize(tag = nil, data = "")
      @aux_no = nil
      @tag = tag
      @creator = nil
      @created_at = nil
      @flags = AuxItemFlags.new()
      @inherit_limit = 0
      @data = data
    end
    def parse(c)
      @aux_no = c.parse_int()
      @tag = c.parse_int()
      @creator = c.parse_int()
      @created_at = c.parse_object(Time)
      @flags = c.parse_object(AuxItemFlags)
      @inherit_limit = c.parse_int()
      @data = c.parse_string()
    end
    def inspect
      return "<AuxItem %d>" % @tag
    end
    def to_string
      return "%d %s %d %dH%s" % [@tag, @flags.to_string(), @inherit_limit, @data.length, @data]
    end
  end
  def all_aux_items_with_tag(ail, tag)
    return ail.select { |x, tag| x.tag == tag }
  end
  def first_aux_items_with_tag(ail, tag)
    all = all_aux_items_with_tag(ail, tag)
    if all.length == 0
      return nil
    else
      return all[0]
    end
  end
  class TextStat
    attr_accessor :creation_time, :author, :no_of_lines, :no_of_chars, :no_of_marks, :misc_info
    def parse(c, old_format = 0)
      @creation_time = c.parse_object(Time)
      @author = c.parse_int()
      @no_of_lines = c.parse_int()
      @no_of_chars = c.parse_int()
      @no_of_marks = c.parse_int()
      @misc_info = c.parse_object(CookedMiscInfo)
      if old_format != 0
        @aux_items = []
      else
        @aux_items = c.parse_array(AuxItem)
      end
    end
  end
  class ConfType
    attr_accessor :rd_prot, :original, :secret, :letterbox, :allow_anonymous, :forbid_secret, :reserved2, :reserved3
    def initialize
      @rd_prot = 0
      @original = 0
      @secret = 0
      @letterbox = 0
      @allow_anonymous = 0
      @forbid_secret = 0
      @reserved2 = 0
      @reserved3 = 0
    end
    def parse(c, old_format = 0)
      if old_format != 0
        @rd_prot, @original, @secret, @letterbox = c.parse_bitstring(4)
        @allow_anonymous, @forbid_secret, @reserved2, @reserved3 = [0, 0, 0, 0]
      else
        @rd_prot, @original, @secret, @letterbox, @allow_anonymous, @forbid_secret, @reserved2, @reserved3 = c.parse_bitstring(8)
      end
    end
    def to_string
      return "%d%d%d%d%d%d%d%d" % [@rd_prot, @original, @secret, @letterbox, @allow_anonymous, @forbid_secret, @reserved2, @reserved3]
    end
  end
  class Conference
    attr_accessor :name, :type, :creation_time, :last_written, :creator, :presentation, :supervisor, :permitted_submitters, :super_conf, :msg_of_day, :nice, :keep_commented, :no_of_members, :first_local_no, :no_of_texts, :expire, :aux_items
    def parse(c)
      @name = c.parse_string()
      @type = c.parse_object(ConfType)
      @creation_time = c.parse_object(Time)
      @last_written = c.parse_object(Time)
      @creator = c.parse_int()
      @presentation = c.parse_int()
      @supervisor = c.parse_int()
      @permitted_submitters = c.parse_int()
      @super_conf = c.parse_int()
      @msg_of_day = c.parse_int()
      @nice = c.parse_int()
      @keep_commented = c.parse_int()
      @no_of_members = c.parse_int()
      @first_local_no = c.parse_int()
      @no_of_texts = c.parse_int()
      @expire = c.parse_int()
      @aux_items = c.parse_array(AuxItem)
    end
    def inspect
      return "<Conference %s>" % @name
    end
  end
  class UConference
    attr_accessor :name, :type, :highest_local_no, :nice
    def parse(c)
      @name = c.parse_string()
      @type = c.parse_object(ConfType)
      @highest_local_no = c.parse_int()
      @nice = c.parse_int()
    end
    def inspect
      return "<UConference %s>" % @name
    end
  end
  class PrivBits
    attr_accessor :wheel, :admin, :statistic, :create_pers, :create_conf, :change_name, :flg7, :flg8, :flg9, :flg10, :flg11, :flg12, :flg13, :flg14, :flg15, :flg16, :wheel, :admin, :statistic, :create_pers, :create_conf, :change_name, :flg7, :flg8, :flg9, :flg10, :flg11, :flg12, :flg13, :flg14, :flg15, :flg16
    def initialize
      @wheel = 0
      @admin = 0
      @statistic = 0
      @create_pers = 0
      @create_conf = 0
      @change_name = 0
      @flg7 = 0
      @flg8 = 0
      @flg9 = 0
      @flg10 = 0
      @flg11 = 0
      @flg12 = 0
      @flg13 = 0
      @flg14 = 0
      @flg15 = 0
      @flg16 = 0
    end
    def parse(c)
      @wheel, @admin, @statistic, @create_pers, @create_conf, @change_name, @flg7, @flg8, @flg9, @flg10, @flg11, @flg12, @flg13, @flg14, @flg15, @flg16 = c.parse_bitstring(16)
    end
    def to_string
      return "%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d" % [@wheel, @admin, @statistic, @create_pers, @create_conf, @change_name, @flg7, @flg8, @flg9, @flg10, @flg11, @flg12, @flg13, @flg14, @flg15, @flg16]
    end
  end
  class PersonalFlags
    attr_accessor :unread_is_secret, :flg2, :flg3, :flg4, :flg5, :flg6, :flg7, :flg8, :unread_is_secret, :flg2, :flg3, :flg4, :flg5, :flg6, :flg7, :flg8
    def initialize
      @unread_is_secret = 0
      @flg2 = 0
      @flg3 = 0
      @flg4 = 0
      @flg5 = 0
      @flg6 = 0
      @flg7 = 0
      @flg8 = 0
    end
    def parse(c)
      @unread_is_secret, @flg2, @flg3, @flg4, @flg5, @flg6, @flg7, @flg8 = c.parse_bitstring(8)
    end
    def to_string
      return "%d%d%d%d%d%d%d%d" % [@unread_is_secret, @flg2, @flg3, @flg4, @flg5, @flg6, @flg7, @flg8]
    end
  end
  class Person
    attr_accessor :username, :privileges, :flags, :last_login, :user_area, :total_time_present, :sessions, :created_lines, :created_bytes, :read_texts, :no_of_text_fetches, :created_persons, :created_confs, :first_created_local_no, :no_of_created_texts, :no_of_marks, :no_of_confs
    def parse(c)
      @username = c.parse_string()
      @privileges = c.parse_object(PrivBits)
      @flags = c.parse_object(PersonalFlags)
      @last_login = c.parse_object(Time)
      @user_area = c.parse_int()
      @total_time_present = c.parse_int()
      @sessions = c.parse_int()
      @created_lines = c.parse_int()
      @created_bytes = c.parse_int()
      @read_texts = c.parse_int()
      @no_of_text_fetches = c.parse_int()
      @created_persons = c.parse_int()
      @created_confs = c.parse_int()
      @first_created_local_no = c.parse_int()
      @no_of_created_texts = c.parse_int()
      @no_of_marks = c.parse_int()
      @no_of_confs = c.parse_int()
    end
  end
  class MembershipType
    attr_accessor :invitation, :passive, :secret, :passive_message_invert, :reserved2, :reserved3, :reserved4, :reserved5, :invitation, :passive, :secret, :passive_message_invert, :reserved2, :reserved3, :reserved4, :reserved5
    def initialize
      @invitation = 0
      @passive = 0
      @secret = 0
      @passive_message_invert = 0
      @reserved2 = 0
      @reserved3 = 0
      @reserved4 = 0
      @reserved5 = 0
    end
    def parse(c)
      @invitation, @passive, @secret, @passive_message_invert, @reserved2, @reserved3, @reserved4, @reserved5 = c.parse_bitstring(8)
    end
    def to_string
      return "%d%d%d%d%d%d%d%d" % [@invitation, @passive, @secret, @passive_message_invert, @reserved2, @reserved3, @reserved4, @reserved5]
    end
  end
  class Membership10
    attr_accessor :position, :last_time_read, :conference, :priority, :last_text_read, :read_texts, :added_by, :added_at, :type
    def parse(c)
      @position = c.parse_int()
      @last_time_read = c.parse_object(Time)
      @conference = c.parse_int()
      @priority = c.parse_int()
      @last_text_read = c.parse_int()
      @read_texts = c.parse_array_of_int()
      @added_by = c.parse_int()
      @added_at = c.parse_object(Time)
      @type = c.parse_object(MembershipType)
    end
  end
  Membership = Membership10
  class ReadRange
    attr_accessor :first_read, :last_read, :first_read, :last_read
    def initialize(first_read = 0, last_read = 0)
      @first_read = first_read
      @last_read = last_read
    end
    def parse(c)
      @first_read = c.parse_int()
      @last_read = c.parse_int()
    end
    def inspect
      return "<ReadRange %d-%d>" % [@first_read, @last_read]
    end
    def to_string
      return "%d %d" % [@first_read, @last_read]
    end
  end
  class Membership11
    attr_accessor :position, :last_time_read, :conference, :priority, :read_ranges, :added_by, :added_at, :type
    def parse(c)
      @position = c.parse_int()
      @last_time_read = c.parse_object(Time)
      @conference = c.parse_int()
      @priority = c.parse_int()
      @read_ranges = c.parse_array(ReadRange)
      @added_by = c.parse_int()
      @added_at = c.parse_object(Time)
      @type = c.parse_object(MembershipType)
    end
  end
  class Member
    attr_accessor :member, :added_by, :added_at, :type
    def parse(c)
      @member = c.parse_int()
      @added_by = c.parse_int()
      @added_at = c.parse_object(Time)
      @type = c.parse_object(MembershipType)
    end
  end
  class TextList
    attr_accessor :first_local_no, :texts
    def parse(c)
      @first_local_no = c.parse_int()
      @texts = c.parse_array_of_int()
    end
  end
  class TextNumberPair
    attr_accessor :local_number, :global_number
    def parse(c)
      @local_number = c.parse_int()
      @global_number = c.parse_int()
    end
  end
  class TextMapping
    attr_accessor :range_begin, :range_end, :later_texts_exists, :block_type, :dict, :list
    def parse(c)
      @range_begin = c.parse_int()
      @range_end = c.parse_int()
      @later_texts_exists = c.parse_int()
      @block_type = c.parse_int()
      @dict = {}
      @list = []
      if @block_type == 0
        @type_text = "sparse"
        @sparse_list = c.parse_array(TextNumberPair)
        for tnp in @sparse_list
          @dict[tnp.local_number] = tnp.global_number
          @list.push([tnp.local_number, tnp.global_number])
        end
      elsif @block_type == 1
        @type_text = "dense"
        @dense_first = c.parse_int()
        @dense_texts = c.parse_array_of_int()
        local_number = @dense_first
        for global_number in @dense_texts
          @dict[local_number] = global_number
          @list.push([local_number, global_number])
          local_number = local_number + 1
        end
      else
        raise ProtocolError
      end
    end
    def inspect
      if @later_texts_exists
        more = " (more exists)"
      else
        more = ""
      end
      return "<TextMapping (%s) %d...%d%s>" % [@type_text, @range_begin, @range_end - 1, more]
    end
  end
  class Mark
    attr_accessor :text_no, :type
    def parse(c)
      @text_no = c.parse_int()
      @type = c.parse_int()
    end
    def inspect
      return "<Mark %d (%d)>" % [@text_no, @type]
    end
  end
  class Info
    attr_accessor :version, :conf_pres_conf, :pers_pres_conf, :motd_conf, :kom_news_conf, :motd_of_lyskom, :aux_item_list, :version, :conf_pres_conf, :pers_pres_conf, :motd_conf, :kom_news_conf, :motd_of_lyskom, :aux_item_list
    def initialize
      @version = nil
      @conf_pres_conf = nil
      @pers_pres_conf = nil
      @motd_conf = nil
      @kom_news_conf = nil
      @motd_of_lyskom = nil
      @aux_item_list = []
    end
    def parse(c)
      @version = c.parse_int()
      @conf_pres_conf = c.parse_int()
      @pers_pres_conf = c.parse_int()
      @motd_conf = c.parse_int()
      @kom_news_conf = c.parse_int()
      @motd_of_lyskom = c.parse_int()
      @aux_item_list = c.parse_array(AuxItem)
    end
    def to_string
      return "%d %d %d %d %d %d" % [@version, @conf_pres_conf, @pers_pres_conf, @motd_conf, @kom_news_conf, @motd_of_lyskom]
    end
  end
  class VersionInfo
    attr_accessor :protocol_version, :server_software, :software_version
    def parse(c)
      @protocol_version = c.parse_int()
      @server_software = c.parse_string()
      @software_version = c.parse_string()
    end
    def inspect
      return "<VersionInfo protocol %d by %s %s>" % [@protocol_version, @server_software, @software_version]
    end
  end
  class StaticServerInfo
    attr_accessor :boot_time, :save_time, :db_status, :existing_texts, :highest_text_no, :existing_confs, :existing_persons, :highest_conf_no
    def parse(c)
      @boot_time = c.parse_object(Time)
      @save_time = c.parse_object(Time)
      @db_status = c.parse_string()
      @existing_texts = c.parse_int()
      @highest_text_no = c.parse_int()
      @existing_confs = c.parse_int()
      @existing_persons = c.parse_int()
      @highest_conf_no = c.parse_int()
    end
    def inspect
      return "<StaticServerInfo>"
    end
  end
  class SessionFlags
    attr_accessor :invisible, :user_active_used, :user_absent, :reserved3, :reserved4, :reserved5, :reserved6, :reserved7
    def parse(c)
      @invisible, @user_active_used, @user_absent, @reserved3, @reserved4, @reserved5, @reserved6, @reserved7 = c.parse_bitstring(8)
    end
  end
  class DynamicSessionInfo
    attr_accessor :session, :person, :working_conference, :idle_time, :flags, :what_am_i_doing
    def parse(c)
      @session = c.parse_int()
      @person = c.parse_int()
      @working_conference = c.parse_int()
      @idle_time = c.parse_int()
      @flags = c.parse_object(SessionFlags)
      @what_am_i_doing = c.parse_string()
    end
  end
  class StaticSessionInfo
    attr_accessor :username, :hostname, :ident_user, :connection_time
    def parse(c)
      @username = c.parse_string()
      @hostname = c.parse_string()
      @ident_user = c.parse_string()
      @connection_time = c.parse_object(Time)
    end
  end
  class SchedulingInfo
    attr_accessor :priority, :weight
    def parse(c)
      @priority = c.parse_int()
      @weight = c.parse_int()
    end
  end
  class WhoInfo
    attr_accessor :person, :working_conference, :session, :what_am_i_doing, :username
    def parse(c)
      @person = c.parse_int()
      @working_conference = c.parse_int()
      @session = c.parse_int()
      @what_am_i_doing = c.parse_string()
      @username = c.parse_string()
    end
  end
  class StatsDescription
    attr_accessor :what, :when
    def parse(c)
      @what = c.parse_array_of_string()
      @when = c.parse_array_of_int()
    end
    def inspect
      return "<StatsDescription>"
    end
  end
  class Stats
    attr_accessor :average, :ascent_rate, :descent_rate
    def parse(c)
      @average = c.parse_float()
      @ascent_rate = c.parse_float()
      @descent_rate = c.parse_float()
    end
    def inspect
      return "<Stats %f + %f - %f>" % [@average, @ascent_rate, @descent_rate]
    end
  end
  class Connection
    attr_accessor :socket, :host, :port, :req_id, :req_queue, :resp_queue, :error_queue, :req_histo, :rb, :rb_len, :rb_pos, :async_handlers, :req_id, :req_histo, :rb_pos, :rb_pos
    def initialize(host, port = 4894, user = "", localbind = nil)
      @socket = TCPSocket.new(host, port)
      @host = host
      @port = port
      @req_id = 0
      @req_queue = {}
      @resp_queue = {}
      @error_queue = {}
      @req_histo = nil
      @rb = ""
      @rb_len = 0
      @rb_pos = 0
      @async_handlers = {}
      send_string("A%dH%s\n" % [user.length, user])
      resp = receive_string(7)
      if resp != "LysKOM\n"
        raise BadInitialResponse
      end
    end
    def add_async_handler(msg_no, handler)
      if not ASYNC_DICT.has_key?(msg_no)
        raise UnimplementedAsync
      end
      if @async_handlers.has_key?(msg_no)
        @async_handlers[msg_no].push(handler)
      else
        @async_handlers[msg_no] = [handler]
      end
    end
    def register_request(req)
      @req_id = @req_id + 1
      @req_queue[@req_id] = req
      if @req_histo != nil
        name = req.__class__.__name__
        begin
          @req_histo[name] = @req_histo[name] + 1
        rescue KeyError
          @req_histo[name] = 1
        end
      end
      return @req_id
    end
    def wait_and_dequeue(id)
      while not @resp_queue.has_key?(id) and not @error_queue.has_key?(id)
        parse_server_message()
      end
      if @resp_queue.has_key?(id)
        ret = @resp_queue[id]
        @resp_queue.delete(id)
        return ret
      else
        error_no, error_status = @error_queue[id]
        @error_queue.delete(id)
        raise ERROR_DICT[error_no]
      end
    end
    def parse_present_data
      while select([@socket], [], [], 0)#[0]
        ch = receive_char()
        if WHITESPACE.include?(ch)
          next
        end
        if ch == "="
          parse_response()
        elsif ch == "%"
          parse_error()
        elsif ch == ":"
          parse_asynchronous_message()
        else
          raise ProtocolError
        end
      end
    end
    def enable_req_histo
      @req_histo = {}
    end
    def show_req_histo
      l = @req_histo.items().map { |x| [-x[1], x[0]] }
      l.sort()
      puts("Count  Request")
      for negcount, name in l
        puts("%5d: %s" % [-negcount, name])
      end
    end
    def parse_server_message
      ch = parse_first_non_ws()
      if ch == "="
        parse_response()
      elsif ch == "%"
        parse_error()
      elsif ch == ":"
        parse_asynchronous_message()
      else
        raise ProtocolError
      end
    end
    def parse_response
      id = parse_int()
      if @req_queue.has_key?(id)
        req = @req_queue[id]
        resp = @req_queue[id].parse_response()
        @req_queue.delete(id)
        @resp_queue[id] = resp
        req.invoke_callback
      else
        raise BadRequestId
      end
    end
    def parse_error
      id = parse_int()
      error_no = parse_int()
      error_status = parse_int()
      if @req_queue.has_key?(id)
        req = @req_queue[id]
        @req_queue.delete(id)
        @error_queue[id] = [error_no, error_status]
        req.invoke_callback
      else
        raise BadRequestId
      end
    end
    def parse_asynchronous_message
      no_args = parse_int()
      msg_no = parse_int()
      if ASYNC_DICT.has_key?(msg_no)
        msg = ASYNC_DICT[msg_no].new()
        msg.parse(self)
        if @async_handlers.has_key?(msg_no)
          for handler in @async_handlers[msg_no]
            handler.call(msg, self)
          end
        end
      else
        raise UnimplementedAsync
      end
    end
    def parse_object(classname)
      obj = classname.new()
      obj.parse(self)
      return obj
    end
    def parse_old_object(classname)
      obj = classname.new()
      obj.parse(self, 1)
      return obj
    end
    def parse_array(element_class)
      len = parse_int()
      res = []
      if len > 0
        left = parse_first_non_ws()
        if left == "*"
          return []
        elsif left != "{"
          raise ProtocolError
        end
        for i in 0...len
          obj = element_class.new()
          obj.parse(self)
          res.push(obj)
        end
        right = parse_first_non_ws()
        if right != "}"
          raise ProtocolError
        end
      else
        star = parse_first_non_ws()
        if star != "*"
          raise ProtocolError
        end
      end
      return res
    end
    def array_to_string(array)
      return "%d { %s }" % [array.length, array.map { |x| x.to_string() }.join(" ")]
    end
    def parse_array_of_basictype(basic_type_parser)
      len = parse_int()
      res = []
      if len > 0
        left = parse_first_non_ws()
        if left == "*"
          return []
        elsif left != "{"
          raise ProtocolError
        end
        for i in range(0, len)
          res.push(send(basic_type_parser))
        end
        right = parse_first_non_ws()
        if right != "}"
          raise ProtocolError
        end
      else
        star = parse_first_non_ws()
        if star != "*"
          raise ProtocolError
        end
      end
      return res
    end
    def parse_array_of_int
      return parse_array_of_basictype(:parse_int)
    end
    def array_of_int_to_string(array)
      return "%d { %s }" % [array.length, array.join(" ")]
    end
    def parse_array_of_string
      return parse_array_of_basictype(:parse_string)
    end
    def parse_bitstring(len)
      res = []
      char = parse_first_non_ws()
      for i in 0...len
        if char == "0"
          res.push(0)
        elsif char == "1"
          res.push(1)
        else
          raise ProtocolError
        end
        char = receive_char()
      end
      return res
    end
    def parse_first_non_ws
      c = receive_char()
      while WHITESPACE.include?(c)
        c = receive_char()
      end
      return c
    end
    def parse_int_and_next
      c = parse_first_non_ws()
      n = 0
      while DIGITS.include?(c)
        n = n * 10 + c[0] - ORD_0
        c = receive_char()
      end
      return [n, c]
    end
    def parse_int
      c, n = parse_int_and_next()
      return c
    end
    def parse_float
      c = parse_first_non_ws()
      digs = []
      while float_chars.include?(c)
        digs.push(c)
        c = receive_char()
      end
      return float("".join(digs))
    end
    def parse_string
      len, h = parse_int_and_next()
      if h != "H"
        raise ProtocolError
      end
      return receive_string(len)
    end
    def send_string(s)
      while s.length > 0
        begin
          done = @socket.syswrite(s)
        rescue SystemCallError => e
          retry if e.errno == Errno::EINTR::Errno
        end
        s = s[done..-1]
      end
    end
    def ensure_receive_buffer_size(size)
      present = @rb_len - @rb_pos
      while present < size
        needed = size - present
        wanted = [needed, 128].max
        begin
          data = @socket.sysread(wanted)
        rescue SystemCallError => e
          if e.errno == Errno::EINTR::Errno
            retry
          else
            raise
          end
        end
        if data.length == 0
          raise ReceiveError
        end
        @rb = @rb[@rb_pos..-1] + data
        @rb_pos = 0
        @rb_len = @rb.length
        present = @rb_len
      end
    end
    def receive_string(len)
      ensure_receive_buffer_size(len)
      res = @rb[@rb_pos..@rb_pos + len-1]
      @rb_pos = @rb_pos + len
      return res
    end
    def receive_char
      ensure_receive_buffer_size(1)
      res = @rb[@rb_pos, 1]
      @rb_pos = @rb_pos + 1
      return res
    end
  end
  class CachedConnection < Connection
    attr_accessor :uconferences, :conferences, :persons, :textstats, :subjects
    def initialize(host, port = 4894, user = "", localbind = nil)
      super(host, port, user, localbind)
      @uconferences = Cache.new(method('fetch_uconference'), "UConference")
      @conferences = Cache.new(method('fetch_conference'), "Conference")
      @persons = Cache.new(method('fetch_person'), "Person")
      @textstats = Cache.new(method('fetch_textstat'), "TextStat")
      @subjects = Cache.new(method('fetch_subject'), "Subject")
      add_async_handler(ASYNC_NEW_NAME, @cah_new_name)
      add_async_handler(ASYNC_LEAVE_CONF, @cah_leave_conf)
      add_async_handler(ASYNC_DELETED_TEXT, @cah_deleted_text)
      add_async_handler(ASYNC_NEW_TEXT, @cah_new_text)
      add_async_handler(ASYNC_NEW_RECIPIENT, @cah_new_recipient)
      add_async_handler(ASYNC_SUB_RECIPIENT, @cah_sub_recipient)
      add_async_handler(ASYNC_NEW_MEMBERSHIP, @cah_new_membership)
    end
    def fetch_uconference(no)
      return ReqGetUconfStat.new(self, no).response()
    end
    def fetch_conference(no)
      return ReqGetConfStat.new(self, no).response()
    end
    def fetch_person(no)
      return ReqGetPersonStat.new(self, no).response()
    end
    def fetch_textstat(no)
      return ReqGetTextStat.new(self, no).response()
    end
    def fetch_subject(no)
      subject = ReqGetText.new(self, no, 0, 200).response()
      pos = string.find(subject, "\n")
      if pos != -1
        subject = subject[0..pos-1]
      end
      return subject
    end
    def cah_new_name(msg, c)
      @uconferences.invalidate(msg.conf_no)
      @conferences.invalidate(msg.conf_no)
    end
    def cah_leave_conf(msg, c)
      @conferences.invalidate(msg.conf_no)
    end
    def cah_deleted_text(msg, c)
      ts = msg.text_stat
      for rcpt in ts.misc_info.recipient_list
        @conferences.invalidate(rcpt.recpt)
      end
    end
    def cah_new_text(msg, c)
      for rcpt in msg.text_stat.misc_info.recipient_list
        @conferences.invalidate(rcpt.recpt)
        @uconferences.invalidate(rcpt.recpt)
      end
    end
    def cah_new_recipient(msg, c)
      @conferences.invalidate(msg.conf_no)
      @uconferences.invalidate(msg.conf_no)
      @textstats.invalidate(msg.text_no)
    end
    def cah_sub_recipient(msg, c)
      @conferences.invalidate(msg.conf_no)
      @textstats.invalidate(msg.text_no)
    end
    def cah_new_membership(msg, c)
      @conferences.invalidate(msg.conf_no)
    end
    def report_cache_usage
      @uconferences.report()
      @conferences.report()
      @persons.report()
      @textstats.report()
      @subjects.report()
    end
    def conf_name(conf_no, default = "", include_no = 0)
      begin
        conf_name = @uconferences[conf_no].name
        if include_no != 0
          return "%s (#%d)" % [conf_name, conf_no]
        else
          return conf_name
        end
#       rescue
#         if default.include? "%d"
#           return default % conf_no
#         else
#           return default
#         end
      end
    end
    def lookup_name(name, want_pers, want_confs)
      if name[0..1-1] == "#"
        begin
          no = Integer(name[1..-1])
          type = @uconferences[no].type
          name = @uconferences[no].name
          if want_pers and type.letterbox or want_confs and not type.letterbox
            return [[no, name]]
          else
            return []
          end
        rescue
          return []
        end
      else
        matches = ReqLookupZName.new(self, name,
                                     want_pers,
                                     want_confs).response()
        return matches.map { |x| [x.conf_no, x.name] }
      end
    end
    def regexp_lookup(regexp, want_pers, want_confs, case_sensitive = 0)
      if regexp.startswith("#")
        return lookup_name(regexp, want_pers, want_confs)
      end
      if not case_sensitive
        regexp = _case_insensitive_regexp(regexp)
      end
      matches = ReqReZLookup.new(self, name,
                                 want_pers,
                                 want_confs).response()
      return matches.map { |x| [x.conf_no, x.name] }
    end
    def _case_insensitive_regexp(regexp)
      result = ""
      collate_table = super()
      inside_brackets = 0
      for c in regexp
        if c == "["
          inside_brackets = 1
        end
        if inside_brackets != 0
          eqv_chars = c
        else
          eqv_chars = _equivalent_chars(c, collate_table)
        end
        if eqv_chars.length > 1
          result += "[%s]" % eqv_chars
        else
          result += eqv_chars
        end
        if c == "]"
          inside_brackets = 0
        end
      end
      return result
    end
    def _equivalent_chars(c, collate_table)
      c_ord = c[0]
      if c_ord >= collate_table.length
        return c
      end
      result = ""
      norm_char = collate_table[c_ord]
      next_index = 0
      loop do
        next_index = collate_table.find(norm_char, next_index)
        if next_index == -1
          break
        end
        result += chr(next_index)
        next_index += 1
      end
      return result
    end
    def get_unread_texts(person_no, conf_no)
      unread = []
      ms = super()
      ask_for = ms.last_text_read + 1
      more_to_fetch = 1
      while more_to_fetch != 0
        begin
          mapping = super()
          for tuple in mapping.list
            if not ms.read_texts.include?(tuple[0])
              unread.push(tuple)
              ask_for = mapping.range_end
              more_to_fetch = mapping.later_texts_exists
            end
          end
        rescue NoSuchLocalText
          more_to_fetch = 0
        end
      end
      return unread
    end
  end
  class CachedUserConnection < CachedConnection
    attr_accessor :_user_no, :member_confs, :memberships, :no_unread, :_user_no, :member_confs
    def initialize(host, port = 4894, user = "", localbind = nil)
      super(host, port, user, localbind)
      @_user_no = 0
      @member_confs = []
      @memberships = Cache.new(method('fetch_membership'), "Membership")
      @no_unread = Cache.new(method('fetch_unread'), "Number of unread")
    end
    def set_user(user_no, set_member_confs = 1)
      @_user_no = user_no
      if set_member_confs != 0
        set_member_confs()
      end
    end
    def set_member_confs
      @member_confs = get_member_confs()
    end
    def get_user
      return @_user_no
    end
    def get_member_confs
      result = []
      ms_list = super()
      for ms in ms_list
        if not ms.type.passive
          result.push(ms.conference)
        end
      end
      return result
    end
    def is_unread(conf_no, local_no)
      if local_no <= @memberships[conf_no].last_text_read
        return 0
      elsif @memberships[conf_no].read_texts.include?(local_no)
        return 0
      else
        return 1
      end
    end
    def fetch_membership(no)
      return super()
    end
    def fetch_unread(no)
      no_unread = 0
      ms = @memberships[no]
      ask_for = ms.last_text_read + 1
      more_to_fetch = 1
      while more_to_fetch != 0
        begin
          mapping = super()
          for local_num, global_num in mapping.list
            if not ms.read_texts.include?(local_num) and global_num
              no_unread = no_unread + 1
              if no_unread > 500
                return no_unread
              end
            end
          end
          ask_for = mapping.range_end
          more_to_fetch = mapping.later_texts_exists
        rescue NoSuchLocalText
          more_to_fetch = 0
        end
      end
      return no_unread
    end
    def cah_deleted_text(msg, c)
      super(msg, c)
      ts = msg.text_stat
      for rcpt in ts.misc_info.recipient_list
        if @member_confs.include?(rcpt.recpt)
          if is_unread(rcpt.recpt, rcpt.loc_no)
            @no_unread[rcpt.recpt] = @no_unread[rcpt.recpt] - 1
          end
        end
      end
    end
    def cah_new_text(msg, c)
      super(msg, c)
      for rcpt in msg.text_stat.misc_info.recipient_list
        if @member_confs.include?(rcpt.recpt)
          @no_unread[rcpt.recpt] = @no_unread[rcpt.recpt] + 1
        end
      end
    end
    def cah_leave_conf(msg, c)
      super(msg, c)
      @member_confs.remove(msg.conf_no)
    end
    def cah_new_recipient(msg, c)
      super(msg, c)
      if @member_confs.include?(msg.conf_no)
        @no_unread[msg.conf_no] = @no_unread[msg.conf_no] + 1
      end
    end
    def cah_sub_recipient(msg, c)
      super(msg, c)
      if @member_confs.include?(msg.conf_no)
        @no_unread.invalidate(msg.conf_no)
      end
    end
    def cah_new_membership(msg, c)
      super(msg, c)
      if msg.person_no == @_user_no
        @member_confs.push(msg.conf_no)
      end
    end
    def report_cache_usage
      super()
      @memberships.report()
      @no_unread.report()
    end
  end
  class Cache
    attr_accessor :dict, :fetcher, :cached, :uncached, :name
    def initialize(fetcher, name = "Unknown")
      @dict = {}
      @fetcher = fetcher
      @cached = 0
      @uncached = 0
      @name = name
    end
    def [](no)
      if @dict.has_key?(no)
        @cached = @cached + 1
        return @dict[no]
      else
        @uncached = @uncached + 1
        @dict[no] = @fetcher.call(no)
        return @dict[no]
      end
    end
    def []=(no, val)
      @dict[no] = val
    end
    def invalidate(no)
      if @dict.has_key?(no)
        @dict.delete(no)
      end
    end
    def report
      puts("Cache %s: %d cached, %d uncached" % [@name, @cached, @uncached])
    end
  end
end
